# Deploy development version of the CNO and OVN-Kubernetes

## Using pre-built images (at quay.io/mmacias)

Apply override patch so the downstream CNO is not redeployed automatically:
```
curl https://raw.githubusercontent.com/openshift/cluster-network-operator/master/hack/overrides-patch.yaml --output overrides-patch.yaml
oc patch --type=json -p "$(cat overrides-patch.yaml)" clusterversion version
```

You need to patch the [manifests/0000_70_cluster-network-operator_03_deployment.yaml](https://raw.githubusercontent.com/openshift/cluster-network-operator/master/manifests/0000_70_cluster-network-operator_03_deployment.yaml) to run the development versions of the CNO and OVN-K:

```diff
24c24,25
<         image: quay.io/openshift/origin-cluster-network-operator:latest
---
>         image: quay.io/mmaciasl/cluster-network-operator:latest
>         imagePullPolicy: Always
41a43,44
>         - name: NETWORK_PLUGIN
>           value: "OVNKubernetes"
65c68
<           value: "quay.io/openshift/origin-ovn-kubernetes:latest"
---
>           value: "quay.io/mmaciasl/ovn-daemonset-f:latest"
```

Simply run the following command to update it:
```bash
oc apply -f examples/network_operator_deployment.yaml
```

Check image and events:
```bash
oc describe -n openshift-network-operator deployment/network-operator
```

## Compiling yourself the images

### 1. Compile OVN-kubernetes

```
git clone github.com/ovn-org/ovn-kubernetes
cd ovn-kubernetes/go-controller
make
cd ../dist/images/
find ../../go-controller/_output/go/bin/ -maxdepth 1 -type f -exec cp -f {} . \;
echo "ref: $(git rev-parse  --symbolic-full-name HEAD)  commit: $(git rev-parse  HEAD)" > git_info
export OVN_IMAGE=quay.io/mmaciasl/ovn-daemonset-f:latest
docker build -t $OVN_IMAGE -f Dockerfile.fedora .
docker push $OVN_IMAGE
```
(replace `quay.io/mmaciasl` by your own images repo)

### 2. Compile the CNO

```
git clone github.com/openshift/cluster-network-operator
cd cluster-network-operator
podman build -t quay.io/mmaciasl/cluster-network-operator:latest .
podman push quay.io/mmaciasl/cluster-network-operator:latest
```
(replace `quay.io/mmaciasl` by your own images repo)

Then follow the steps of the [Using-pre-built-images](#using-pre-built-images-at-quayiommacias) section, providing your own repository in the image paths.
