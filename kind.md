## KIND

### Setup ovn-kubernetes on KIND

You can follow [this guide](https://github.com/ovn-org/ovn-kubernetes/blob/master/docs/kind.md#ovn-kubernetes-kind-setup) either with docker or podman

### Load local image
You can load any local docker images in kind without pushing them online
`kind load docker-image my-custom-image-0 my-custom-image-1`

Example for dev goflow-kube image on ovn cluster:
`kind load docker-image quay.io/netobserv/goflow-kube:dev --name ovn`

### Enable EphemeralContainers [feature gate](https://kind.sigs.k8s.io/docs/user/configuration/#feature-gates)
Simply add `EphemeralContainers: true` in featureGates section of your kind cluster yaml configuration file

For ovn-kubernetes : `$(go env GOPATH)/src/github.com/ovn-org/ovn-kubernetes/contrib/kind_ephemeral.yaml.j2` 

### Troubleshooting
[github.com/ovn-org/ovn-kubernetes](ovn-kubernetes repository) may be in a non stable state. If you have issues, feel free to checkout previous revision like
commit ac5ce1c951ac3533eebed24ec75fb2ddfcb5adf1 (HEAD -> master)
Date:   Wed Oct 13 11:40:48 2021 -0500

If your kubectl respond connection refused or missing config, check your KUBECONFIG variable 
`export KUBECONFIG=${HOME}/admin.conf`

✗ Joining worker nodes :tractor:
There are various reasons to get this error but you may restart your docker and kubelet services before trying any other fixes

You can use `-wk 1` option to use only one worker and lower ressources usage
