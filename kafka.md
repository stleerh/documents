# Deploy Kafka on Openshift using Strimzi Operator

The easiest way to deploy Kafka on Openshift is using [Strimzi](https://strimzi.io/).
An Operator is available in OperatorHub section.
Simply install it and create a "Kafka" instance in `default` namespace.

## Manual installation of strimzi operator

You can use the following command to deploy the strimzi operator :

```
export NAMESPACE=netobserv
kubectl create -f "https://strimzi.io/install/latest?namespace=$NAMESPACE" -n $NAMESPACE
```
## Update storage class of kafka cluster
```
export DEFAULT_SC=$(kubectl get storageclass -o=jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}')
tmpfile=$(mktemp)
envsubst < ./examples/kafka/default.yaml > $tmpfile && mv $tmpfile ./examples/kafka/default.yaml
```

## Creating the default cluster

A simple Kafka resource, with ephemeral storage and metrics enabled, can be found [here](./examples/kafka/default.yaml).

```
kubectl apply -f ./examples/kafka/metrics-config.yaml -n $NAMESPACE
kubectl apply -f ./examples/kafka/default.yaml -n $NAMESPACE
```

For metrics, a ServiceMonitor resource is provided, so you will need a Prometheus operator installed and able to fetch it.

### mTLS

Alternatively, a secure setup with enforced mutual-TLS is provided:

```
kubectl apply -f ./examples/kafka/metrics-config.yaml -n $NAMESPACE
kubectl apply -f ./examples/kafka/tls.yaml -n $NAMESPACE
```

## Creating a topic

Topics can be managed through the strimzi operator. An example of kafka-topic.yaml can be found [here](./examples/kafka/topic.yaml).

```
kubectl apply -f ./examples/kafka/topic.yaml -n $NAMESPACE
```

## Creating a user

Creating one or several users is necessary for mTLS.

```
kubectl apply -f ./examples/kafka/user.yaml -n $NAMESPACE
kubectl wait --timeout=180s --for=condition=ready kafkauser flp-kafka -n $NAMESPACE
```

When using mTLS, you should wait that the `KafkaUser` resource is ready (meaning: processed by Strimzi user operator) before deploying flowlog-pipeline or the eBPF agent, because they need to mount the generated secret files. Otherwise, the pods are stuck, you would need to delete them in order to restart them.

## Deleting user, topic and cluster

```
kubectl delete -f ./examples/kafka/user.yaml -n $NAMESPACE
kubectl delete -f ./examples/kafka/topic.yaml -n $NAMESPACE
kubectl delete kafka kafka-cluster -n $NAMESPACE
kubectl delete -f ./examples/kafka/metrics-config.yaml -n $NAMESPACE
```

## Tooling

You can use [kfk](https://github.com/systemcraftsman/strimzi-kafka-cli), a CLI for Kafka / Strimzi, to interact with the cluster. Examples:

To create a new user with public/private keys for mTLS, and get its secrets:

```bash
kfk users --create --user flp-kafka --authentication-type tls -n netobserv -c kafka-cluster
kubectl describe secret/flp-kafka -n netobserv
```

To create a terminal-based producer and consumer with mTLS, refer to [this page](https://github.com/systemcraftsman/strimzi-kafka-cli/tree/main/examples/2_tls_authentication).



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
kubectl port-forward svc/kowl 8080:80
```

Open `http://127.0.0.1:8080` to access kowl.
