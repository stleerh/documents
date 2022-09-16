## Documents
This repo contains various documents related to network observability (a.k.a. netobserv):

### Repositories
* [netobserv-operator](https://github.com/netobserv/network-observability-operator)
    OpenShift / Kubernetes operator for network observability.
    This operator will deloy the following components:
    * [eBPF Agent](https://github.com/netobserv/netobserv-ebpf-agent): An eBPF agent that captures and exports network flows.
    * [flowlogs-pipeline](https://github.com/netobserv/flowlogs-pipeline): A configurable flow collector, enricher and metrics producer.
    * [netobserv-plugin](https://github.com/netobserv/network-observability-console-plugin):
    The NetObserv plugin for the Openshift Console.
* [nflow-generator](https://github.com/netobserv/nflow-generator):
A fake legacy v5 netflow generator
* etc.

### Get started
The easiest way to get started is to use the [NetObserv Operator](https://github.com/netobserv/network-observability-operator) that will deploy all the components for you. It is available via [OLM](https://operatorhub.io/operator/netobserv-operator).

You can either:
- [Deploy an existing image](https://github.com/netobserv/network-observability-operator#deploy-an-existing-image)
- [Build from sources](https://github.com/netobserv/network-observability-operator#build--push--deploy)

### Development

You will need a Kubernetes cluster, such as [Kind](./kind.md) or [OpenShift](./openshift.md).

If you don't need the entire stack, you can just [check components](#repositories) above.

### Other links

- [Sample apps](./sample_apps.md): a few suggestions to generate traffic, useful for testing NetObserv.
