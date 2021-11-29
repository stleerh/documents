## Openshift
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