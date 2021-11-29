## Openshift

* [Deploy using OpenShift Container Platform](#deploy-using-openshift-container-platform)
* [Deploy using Cluster Bot](#deploy-using-cluster-bot)

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

### Set OVN-Kubernetes as default CNI network provider on Openshift
This is mandatory for kube-enricher used in network-observability-operator.

#### Using OCP
You can [customize your OCP installation](https://docs.openshift.com/container-platform/4.8/installing/installing_aws/installing-aws-network-customizations.html#installation-initializing_installing-aws-network-customizations) using `install-config.yaml` file.

Generate the configuration using:
```bash
openshift-install create install-config --dir=<installation_directory>
```

Add [network configuration parameters](https://docs.openshift.com/container-platform/4.8/installing/installing_aws/installing-aws-network-customizations.html#installation-configuration-parameters-network_installing-aws-network-customizations)

For example:
```yaml
networking:
  networkType: OVNKubernetes
```

#### Migrate running cluster
Follow the [official guide](https://docs.openshift.com/container-platform/4.8/networking/ovn_kubernetes_network_provider/migrate-from-openshift-sdn.html#nw-ovn-kubernetes-migration_migrate-from-openshift-sdn) for OVNK networkType migration according to your Openshift version.

This can take some time and you will need ssh access or infrastructure provider management portal to restart each nodes so you should consider [using OCP install-config.yaml](####using-ocp)

## Deploy using Cluster Bot

Cluster Bot is a Slack bot that allows easily deploying short-lived clusters (auto-removed in ~2
hours) with concrete in-development branches of several Openshift components.

To use it, just add the `cluster-bot` app in your Slack (usually, in the Apps dropdown from the
Slack left panel) and type `help` in the message Window. It will show you several options.

The deployment takes around 30 minutes. When it finishes, `cluster-bot` provides you the contents
of the `KUBECONFIG` file as well as the `kubeadmin` password.

### Examples

Launch the last 4.x stable version with OVNKubernetes CNI:
`launch 4-stable ovn`

Launch the latest stable version of OpenShift, but replacing the bundled Console and CNO by the
contents of Pull Requests `#9953` and `#1231`, respectively:
 
```
launch openshift/console#9953,openshift/cluster-network-operator#1231
```

Launch an in-development 4.10-ci version of OpenShift, replacing the `master` branch of the
Console by the Pull Request `#9953`:

```
launch 4.10-ci,openshift/console#9953
```



