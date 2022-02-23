# Developing network Operator (on OCP)

The following instructions are useful for local speedy development of the operator.

## prerequisites

1. Local linux machine
2. OCP cluster

## Deployment process

1. Connect to the OCP cluster using `oc login ...`
2. execute `kubectl create namespace network-observability` - this creates the `network-observability` namespace
3. execute `kubectl config set-context --current --namespace network-observability` - this changes the `kubectl` context to `network-observability` namespace
4. Execute `make deploy-loki` - this  deploys a simple loki instance into the cluster
5. Execute `make deploy-grafana ` - this deploys a simple grafana instance into the cluster (user: admin password: admin)
6. Execute `oc patch console.operator.openshift.io cluster --type='json' -p '[{"op": "add", "path": "/spec/plugins", "value": ["network-observability-plugin"]}]'` - this enables the console plugin
   - note: the console plug-in itself is deployed as part of `make run` by the operator. This patch can be applied also post deployment of the console plug-in   
7. Execute `make install` - this installs the operator CRDs into the cluster
8. Execute `make deploy-sample-cr` - this installs an example of *flows.netobserv.io* instance into the cluster
9. Execute `make run` - this starts running the operator process locally (on the laptop, not inside the cluster)
10. Use `kubectl get pods` to see that the pods are deployed as expected
11. Once the `goflow-kube` pod is ready, on OCP 4.9 and earlier, enable IPFIX collection into `goflow-kube` using:
```bash
GF_IP=`oc get svc goflow-kube -n network-observability -ojsonpath='{.spec.clusterIP}'` && echo $GF_IP
oc patch networks.operator.openshift.io cluster --type='json' -p "$(sed -e "s/GF_IP/$GF_IP/" ./config/samples/net-cluster-patch.json)"
``` 

## Notes

> Deployment is done into `network-observability` namespace

> Once executed operator log are emitted to stdout

## Code update process

1. Execute `make undeploy-sample-cr` - this deletes the *flows.netobserv.io* instance. The operator will delete all deployed resources from the cluster
2. Stop the running operator process - after making sure that the resources are removed by the operator in the previous step
3. **Update the operator code** :-)
4. Rerun steps from [Deployment process](#deployment-process) section starting with `make create-sample-cr`

## Troubleshooting

- use `kubectl get pods` to observe the list of pods. Expect to see output such as
```bash
$ kubectl get pods
NAME                                            READY   STATUS    RESTARTS   AGE
goflow-kube-577d8c89b5-sll57                    1/1     Running   0          77s
loki                                            1/1     Running   0          92m
network-observability-plugin-676b6f8c8f-f62qz   1/1     Running   0          77s
```

> Note: expect pod names with different random IDs   

- use `kubectl exec -it goflow-kube-757dcf5c74-8b24w bash` to start shell inside the `goflow-kube` pod
- use `curl http://loki:3100/ready` to validate that Loki is healthy
- use `curl http://localhost:8080/metrics` to validate that goflow-kube is healthy
- 
