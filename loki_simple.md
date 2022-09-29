# Automatic deployment Loki with the Network Observability Operator

In its current status, deploying and configuring the Loki operator with our NOO
[might be a complex task](./hack_loki.md). Basically due to the setup and configuration
of the gateway and the external dependencies towards the Storage Engine. In addition,
different Cloud providers might require different steps and configuration.

This document aims to design the deployment of a simple solution that might allow customers
to deploy a zero-click version of Loki that should be enough for most cases.

## PersistentVolumeClaim and StorageClass

OpenShift will usually provide one or more [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/)
instances that allow our application to use and manage persistent storage backends from different
vendors with a uniform interface.

Initially, our NOO should be deployed with a default `PersistentVolumeClaim` that would contain
some default values, which will be used to store our flows. For example:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: loki-store
spec:
  resources:
    requests:
      storage: 1G
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
```

The above `PersistentVolumeClaim` would make use of the default `StorageClass`. Depending on the
wanted default behavior, we might provide extra `StorageClass` definitions if, e.g., we need to
override the default `reclaimPolicy` or to make use of the [Container Storage Interface](https://docs.openshift.com/container-platform/4.9/storage/container_storage_interface/persistent-storage-csi.html#persistent-storage-csi).

If we needed to provide more fine-grained configuration, we could provide different `StorageClass` + `PersistentVolumeClaim`
pairs of definitions for multiple storage backends (AWS, GCP, NFS...) and execute them selectively depending
on the detected Cloud Provider. For example, to use the AWS EBS CSI provider:

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: loki-csi
  labels:
    app: loki
provisioner: ebs.csi.aws.com
parameters:
  encrypted: 'true'
  type: gp2
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: loki-store
spec:
  storageClassName: loki-csi
  resources:
    requests:
      storage: 1G
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
```

We should also
provide simple and clear instructions to allow some users to create their own
`StorageClass` + `PersistentVolumeClaim` configurations, in case they use some custom/new storage
backend.

Also, observe that all the above `PersistentVolumeClaim` are defined as `volumeMode: Filesystem`,
since it will provide a unified interface for Loki (avoiding any type of extra/custom configuration).

## Basic Loki definition

At this point the Loki Operator is under development (and current install/configuration
instructions seem to be too complex for a zero-click installation). Using the Loki helm charts
would involve extra dependencies and breaking the standard deployment workflow.

We suggest to provide also a simple Loki deployment file that configures it to store the data
in the file system (mounted into the `PersistentVolumeClaim` from the previous section), so
the customer does not need to provide any mean of bucket ID or backend credentials.

A simple example would be:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-config
data:
  local-config.yaml: |
    auth_enabled: false
    server:
      http_listen_port: 3100
      grpc_listen_port: 9096
    common:
      path_prefix: /loki-store
      storage:
        filesystem:
          chunks_directory: /loki-store/chunks
          rules_directory: /loki-store/rules
      replication_factor: 1
      ring:
        instance_addr: 127.0.0.1
        kvstore:
          store: inmemory
    schema_config:
      configs:
        - from: 2020-10-24
          store: boltdb-shipper
          object_store: filesystem
          schema: v11
          index:
            prefix: index_
            period: 24h
    storage_config:
      filesystem:
        directory: /loki-store/storage
      boltdb_shipper:
        active_index_directory: /loki-store/index
        shared_store: filesystem
        cache_location: /loki-store/boltdb-cache
---
apiVersion: v1
kind: Pod
metadata:
  name: loki
  labels:
    app: loki
spec:
  securityContext:
    runAsGroup: 1000
    runAsUser: 1000
    fsGroup: 1000
  volumes:
    - name: loki-store
      persistentVolumeClaim:
        claimName: loki-store
    - name: loki-config
      configMap:
        name: loki-config
  containers:
    - name: loki
      image: grafana/loki:2.6.1
      volumeMounts:
        - mountPath: "/loki-store"
          name: loki-store
        - mountPath: "/etc/loki"
          name: loki-config
---
kind: Service
apiVersion: v1
metadata:
  name: loki
spec:
  selector:
    app: loki
  ports:
    - port: 3100
      protocol: TCP
```

The above example:

* Creates a default `loki.yaml` configuration file, configured for a simple instance.
* Deploys Loki as a single Pod, mounting two volumes:
    - The `loki-store` from the `PersistentVolumeClaim` of the previous section.
    - The `loki-config` configuration map.
* Defines a service to make Loki accessible from the cluster.

We need to examine how we can provide a zero-click deployment that increases the number of
loki instances, and enables HTTPS traffic.

## Hands-on

The [examples/zero-click-loki/](./examples/zero-click-loki) folder of this repository contains
two description files that deploy a zero-click Loki.

You first need to deploy the `PersistentVolumeClaim` instance. Once it is applied, it should
be never removed until you really want that the historical Loki data is removed:

```
oc apply -f examples/zero-click-loki/1-storage.yaml
```

The second file to deploy is the actual loki Pod+Service+Configuration:

```
oc apply -f examples/zero-click-loki/2-loki.yaml
```

You can verify that the service is working from another Pod. E.g:

```
$ oc run -it --image hoverinc/curl -- bash
# curl http://loki:3100/loki/api/v1/labels
{"status":"success","data":["__name__"]}
# curl "http://loki:3100/loki/api/v1/push" -XPOST -H "Content-Type: application/json" --data-raw \
>  "{\"streams\": [{ \"stream\": { \"foo\": \"bar2\" }, \"values\": [ [ \"$(date -u +%s)000000000\", \"fizzbuzz\" ] ] }]}"
# curl http://loki:3100/loki/api/v1/labels
{"status":"success","data":["__name__","foo"]}
```

To verify that the Loki data is persisted, let's remove/redeploy the Loki Pod (but not the
`PersistentVolumeClaim`):

```
$ oc delete -f examples/zero-click-loki/2-loki.yaml
configmap "loki-config" deleted
pod "loki" deleted
service "loki" deleted
$ oc apply -f examples/zero-click-loki/2-loki.yaml
configmap/loki-config created
pod/loki created
service/loki created
```

Then, from the `curl` Pod, let's query again for the existing labels. Observe that the `foo`
label from the previous deployment is still there:

```
curl http://loki:3100/loki/api/v1/labels
{"status":"success","data":["__name__","foo"]}
```

## Conclusions

The previous examples demonstrate that it is possible to provide a zero-click Loki deployment
with persistent storage.

However, we still would need to define some extra details before releasing it:
* `StorageClass`
  * is default `StorageClass` enough?
  * Should we configure it with `reclaimPolicy: Retain`?
  * Should we use the [Container Storage Interface](https://docs.openshift.com/container-platform/4.9/storage/container_storage_interface/persistent-storage-csi.html#persistent-storage-csi)?
* `PersistentVolumeClaim`
  * To decide the size
  * To decide the accessModes
* Loki `Deployment`
  * To configure it with multiple collector instances, we should deploy an extra component to
    coordinate the instances ring. In past experiments,
    [we succeeded providing a simple Consul deployment](https://github.com/mariomac/storage-backends).
* Configure the NOO to:
    - Use the simple Loki service described in this document.
    - Provide a simple way to override some default values of this Loki service.
    - Not deploying any Loki and make use of a user-provided Loki endpoint.