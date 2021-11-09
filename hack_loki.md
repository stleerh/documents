# Hacks on Loki & Grafana

## Loki Operator

### From Sources

Clone loki-operator repository and open folder
```bash
git clone https://github.com/ViaQ/loki-operator.git
cd loki-operator
```

Disable loki auth for development in [loki-config.yaml](https://github.com/ViaQ/loki-operator/blob/master/internal/manifests/internal/config/loki-config.yaml#L2)
`sed -i 's/auth_enabled: true/auth_enabled: false/g' /internal/manifests/internal/config/loki-config.yaml`

Build and push the container image and then deploy the operator
`make oci-build oci-push deploy REGISTRY_ORG=netobserv VERSION=latest`

Create a LokiStack instance to get the various components of Loki up and running
`kubectl apply -f hack/lokistack_dev.yaml`

### From image (WARNING WIP, need kubectl [1.23.0-alpha.4](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG/CHANGELOG-1.23.md#v1230-alpha4) or more. Issues on /host access in debug ephemeral container)

Get operator from official image and create instance
```bash
kubectl apply -f examples/lokioperator.yaml
kubectl apply -f examples/lokistack_dev.yaml
```

Get controller manager name
`kubectl get pods -l name=loki-operator-controller-manager`

Create ephemeral container using controller manager name like :
`kubectl debug controller-manager-9cb578d85-5dcxg -it --target=manager --image=busybox`

Disable auth in loki config 
`sed -i 's/auth_enabled: true/auth_enabled: false/g' /host/workspace/internal/manifests/internal/config/loki-config.yaml`

Then restart all loki pods to update configmap
`kubectl get pods -n default --no-headers=true | awk '/loki-/{print $1}'| xargs  kubectl delete -n default pod`

## Loki & Grafana stack with Helm

```bash
helm upgrade --install loki grafana/loki-stack --set promtail.enabled=false
helm install loki-grafana grafana/grafana
```

Wait for the service running then forward port
`kubectl port-forward service/loki-grafana 3000:3000`

Login : `admin`
Password should be retreive with :
`kubectl get secret loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`

## Grafana from Image

Create [grafana instance](https://grafana.com/docs/grafana/latest/installation/kubernetes/) from official image
`kubectl apply -f examples/grafana.yaml`

Wait for the service running then forward port
`kubectl port-forward service/grafana 3000:3000`

Login : `admin`
Password : `admin`
Info : You can skip password definition or change it at first login

## Grafana Usage

Open http://localhost:3000/ and login with `admin` + password according to previous sections

Select "add datasource" => "Loki" and set your source :
- `http://loki:3100` for helm
- `http://loki-query-frontend-http-lokistack-dev.default.svc.cluster.local:3100` for loki-operator

You should get "Data source connected and labels found." after clicking Save & Test button

Example of queries:
- View raw logs:
`{app="goflow2"}`

- Top 10 sources by volumetry (1 min-rate):
`topk(10, (sum by(SrcWorkload,SrcNamespace) ( rate({ app="goflow2" } | json | __error__="" | unwrap Bytes [1m]) )))`

- Top 10 destinations for a given source (1 min-rate):
`topk(10, (sum by(DstWorkload,DstNamespace) ( rate({ app="goflow2",SrcNamespace="default",SrcWorkload="goflow" } | json | __error__="" | unwrap Bytes [1m]) )))`