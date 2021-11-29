## Documents
This repo contains various documents related to this "netobserv" initiative.

### Repositories
* [network-observability-operator](https://github.com/netobserv/network-observability-operator)
    OpenShift / Kubernetes operator for network observability.
    This operator will deloy the following components:
    * [goflow2-kube-enricher](https://github.com/netobserv/goflow2-kube-enricher)
        This component implements the following libraries:
        * [loki-client-go](https://github.com/netobserv/loki-client-go)
        An HTTP client to send logs to Loki server
        * [goflow2-loki-exporter](https://github.com/netobserv/goflow2-loki-exporter)
        A Loki exporter plugin
    * [network-observability-console-plugin](https://github.com/netobserv/network-observability-console-plugin)
    Network Observability plugin for the Openshift Console

### Get started
The easiest way to get started is to use the [Network Observability Operator](https://github.com/netobserv/network-observability-operator) that will deploy all the components for you.

You can either:
- [Deploy an existing image](https://github.com/netobserv/network-observability-operator#deploy-an-existing-image)
- [Build from sources](https://github.com/netobserv/network-observability-operator#build--push--deploy)

You will need [Kind](./kind.md) or [OpenShift](./openshift.md) with ovn-kubernetes configured to get network flows.

If you don't need the entire stack, you can just [check components](###repositories) above.