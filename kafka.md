# Deploy Kafka on Openshift using Strimzi Operator

The easiest way to deploy Kafka on Openshift is using [Strimzi](https://strimzi.io/).
An Operator is available in OperatorHub section.
Simply install it and create a "Kafka" instance in `default` namespace.

## Manual installation of strimzi operator

You can use the following command to deploy the strimzi operator :

```
export NAMESPACE=network-observability
kubectl create -f "https://strimzi.io/install/latest?namespace=$NAMESPACE" -n $NAMESPACE
```

## Creating the cluster

An example of kafka-cluster.yaml file can be found [here](./examples/kafka-cluster.yaml).

```
kubectl apply -f ./examples/kafka-cluster.yaml -n $NAMESPACE
```

## Creating a topic

Topics can be managed with through the strimzi operator. An example of kafka-topic.yaml can be found [here](./examples/kafka-topic.yaml)

```
kubectl apply -f ./examples/kafka-topic.yaml -n $NAMESPACE
```

## Deleting the topic and the cluster

```
kubectl delete -f ./examples/kafka-cluster.yaml -n $NAMESPACE
kubectl delete -f ./examples/kafka-topic.yaml -n $NAMESPACE
```

# Deploy a Kafka Producer

You can either deploy `goflow2` or `kube-enricher` as Kafka producers. The main difference is that `kube-enricher` allows you to add kubernetes datas from flows. Check [README.md](https://github.com/netobserv/goflow2-kube-enricher/blob/main/README.md) for more details.

## kube-enricher
Check [goflow-kube-kafka-exporter.yaml](https://github.com/netobserv/goflow2-kube-enricher/blob/main/examples/goflow-kube-kafka-exporter.yaml) from `oflow2-kube-enricher` repository in `goflow2-kube-enricher/examples/` folder.

Edit brokers parameter according to your needs and run:
```bash
oc apply -f examples/goflow-kube-kafka-exporter.yaml
```

You can set fields used for partition hash by setting `hashKeys`:
```yaml
  config.yaml: |
    ...
    kafka:
      version: 3.0.0
      export:
        hashKeys:
          - TimeReceived
          - SrcAddr
          - SrcMac
          - DstAddr
          - DstMac
```
Else it will choose partition randomly.

By default the following options will be used:
```go
Version: "2.8.0",
TLS:     false,
SASL:    nil,
Topic:   "goflow-kube",
...
Keys:           []string{},
Brokers:        []string{},
MaxMsgBytes:    1024 * 1024,      // 1mb
FlushBytes:     10 * 1024 * 1024, // 10 mb
FlushFrequency: 5 * time.Second,
```

Check [config.go](https://github.com/netobserv/goflow2-kube-enricher/blob/main/pkg/config/config.go) for more details

## goflow2 
Take a look at file [goflow2-karka.yaml](./examples/goflow2-kafka.yaml)

Edit command arguments according to your needs:
`-loglevel=trace` to set logrus log level to trace
`-listen=netflow://:2055` defines netflow version and listening port
`-transport=kafka` will send output to kafka 
`-transport.kafka.brokers=my-cluster-kafka-brokers.default.svc.cluster.local:9092` set the kafka broker url and port
`-transport.kafka.topic=goflow-kube` set the kafka topic 
`-transport.kafka.hashing=true` allow partition
`-format.hash=TimeReceived,SamplerAddress,SrcAddr,SrcPort,SrcMac,DstAddress,DstPort,DstMac` fields used for partition hash

Then deploy goflow2:
```bash
oc apply -f examples/goflow2-kafka.yaml
```

You can optionally create a route to view metrics using the following configuration:
```yaml
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: goflow2
  namespace: default
spec:
  path: /metrics
  to:
    kind: Service
    name: goflow2
    weight: 100
  port:
    targetPort: metrics
  wildcardPolicy: None
```

As soon as `goflow2` will send it's firsts flows, you will see a new Kafka Topic in Installed Operators > Strimzi Operator details > Kafka Topics
Here we expect `goflow-kube`

You can edit the associated yaml to increase partition number:
```yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
spec:
  ...
  partitions: 5
  ...
  topicName: goflow-kube
```

# Deploy a Kafka Consumer

Check [goflow-kube-kafka-consumer.yaml](https://github.com/netobserv/goflow2-kube-enricher/blob/main/examples/goflow-kube-kafka-consumer.yaml) from `oflow2-kube-enricher` repository in `goflow2-kube-enricher/examples/` folder.

You will need to specify kafka broker url and port in the `listen` config option and optionally `version` in `kafka` section. 
```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: goflow-kube-kafka-config
data:
  config.yaml: |
    listen: my-cluster-kafka-bootstrap.default.svc.cluster.local:9092
    kafka:
      version: 3.0.0
```

By default the following options will be used:
```go
Version: "2.8.0",
TLS:     false,
SASL:    nil,
Topic:   "goflow-kube",
...
Group:               "goflow-kube",
BalanceStrategy:     "range",
InitialOffsetOldest: true,
Backoff:             2 * time.Second,
MaxWaitTime:         5 * time.Second,
MaxProcessingTime:   1 * time.Second,
```

Check [config.go](https://github.com/netobserv/goflow2-kube-enricher/blob/main/pkg/config/config.go) for more details

# Web UI for Kafka using Kowl
Check [kowl.yaml](examples/kowl.yaml) file and update broker URL and extraVolumes if needed.

Then run the following commands to create a Kowl instance:
```bash
helm repo add cloudhut https://raw.githubusercontent.com/cloudhut/charts/master/archives
helm repo update
helm upgrade --install -f examples/kowl.yaml kowl cloudhut/kowl
```

You should get a prompt showing status `deployed`

Then run:
```bash
export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=kowl,app.kubernetes.io/instance=kowl" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace default port-forward $POD_NAME 8080:8080
```

Open `http://127.0.0.1:8080` to access kowl.