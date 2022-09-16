# Openshift

## Deploy using OpenShift Container Platform

The easiest way to get Openshift installed is using [OpenShift Container Platform](https://docs.openshift.com/container-platform/4.8/installing/index.html)

### Machines types
You can set [AWS machines types](https://docs.openshift.com/container-platform/4.8/installing/installing_aws/installing-aws-customizations.html#installation-supported-aws-machine-types_installing-aws-customizations) or [GCP machines types](https://docs.openshift.com/container-platform/4.8/installing/installing_gcp/installing-gcp-customizations.html#installation-configuration-parameters-additional-gcp_installing-gcp-customizations) to your master and workers nodes using `plaform` parameter in your `install-config.yaml` file.

Example for AWS:
```yaml
platform:
    aws:
      type: c5.4xlarge
```

Example for GCP:
```yaml
  platform:
    gcp:
      type: n2-standard-4
```

This allow you to get more ressources in order to deploy Loki for example.

#### Using OCP
You can [customize your OCP installation](https://docs.openshift.com/container-platform/4.8/installing/installing_aws/installing-aws-network-customizations.html#installation-initializing_installing-aws-network-customizations) using `install-config.yaml` file.

Generate the configuration using:
```bash
openshift-install create install-config --dir=<installation_directory>
```

## Metrics

NetObserv comes with a bunch of metrics, however they are not scraped by default by OpenShift Cluster Monitoring (the OpenShift cluster Prometheus that is used for infra monitoring).

You can install your own Prometheus to scrape NetObserv's metrics.

As an alternative, you can also tell OpenShift Cluster Monitoring to scrape all user metrics, not just infra (provided as "USE AT YOUR OWN RISK": depending on your running workloads and their metrics, it may put pressure on Prometheus and make it unstable).

We provide some YAML to do so:

```bash
oc apply -f https://raw.githubusercontent.com/netobserv/documents/main/examples/metrics/monitoring.yaml
```

It will create a `Service` for flowlogs-pipeline metrics, two `ServiceMonitors` (for flowlogs-pipeline and the console plugin), and configure Cluster Monitoring to scrape user metrics.

The generated metrics are prefixed with `netobserv_` or `flow_`.
