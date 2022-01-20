# Deploy Kafka on Openshift using Strimzi Operator

The easiest way to deploy Kafka on Openshift is using [Strimzi](https://strimzi.io/).
An Operator is available in OperatorHub section. Simply install it and create a "Kafka" instance.

The default settings will create a bunch of Kafka Brokers and Zookeepers in `openshift-operators` namespace.

# Deploy goflow2 as Kafka Producer

Take a look at file [goflow2-karka.yaml](./examples/goflow2-kafka.yaml)

Edit command arguments according to your needs:
`-loglevel=trace` to set logrus log level to trace
`-listen=netflow://:2055` defines netflow version and listening port
`-transport=kafka` will send output to kafka 
`-transport.kafka.brokers=my-cluster-kafka-brokers.openshift-operators.svc.cluster.local:9092` set the kafka broker url and port
`-transport.kafka.topic=goflow-kube` set the kafka topic 
`-transport.kafka.hashing=true` allow partition
`-format.hash=TimeReceived,SamplerAddress,SrcAddr,SrcPort,SrcMac,DstAddress,DstPort,DstMac` fields used for partition hash

Then deploy goflow2:
```
oc apply -f examples/goflow2-kafka.yaml
```

# Deploy kube-enricher as Kafka Consumer

Check [goflow-kube-kafka.yaml](https://github.com/netobserv/goflow2-kube-enricher/blob/main/examples/goflow-kube-legacy.yaml) in `goflow2-kube-enricher/examples/`

You will need to specify kafka broker url and port in the `listen` config option and optionally `version` in `kafka` section. 
```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: goflow-kube-kafka-config
data:
  config.yaml: |
    listen: my-cluster-kafka-bootstrap.openshift-operators.svc.cluster.local:9092
    kafka:
      version 3.0.0
```

By default the following options will be used:
```go
Group:               "goflow-kube",
BalanceStrategy:     "range",
InitialOffsetOldest: true,
Version:             "2.8.0",
TLS:                 false,
Topic:               "goflow-kube",
```

Check [config.go](https://github.com/netobserv/goflow2-kube-enricher/blob/main/pkg/config/config.go) for more details

