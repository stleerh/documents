# Hacks on Loki & Grafana
This file will help you using [loki-operator](https://github.com/ViaQ/loki-operator) since it's still WIP project.
You can check [this PR](https://github.com/ViaQ/loki-operator/pull/99) for dev usage and the [README.md](https://github.com/ViaQ/loki-operator/blob/master/README.md) file for status

## Loki Operator on Kind
Loki operator can be run without gateway for debug on kind. It will create the same ressources as helm lokistack installation:
`distributor`, `compactor`, `ingester`, `querier`, `query-frontend`

Check [loki components](https://grafana.com/docs/loki/latest/fundamentals/architecture/#components) before getting started.

### Requirements
- Install kubectl CLI for communicating with the cluster.
- Running Kubernetes cluster using kind.
- A container registry that you and your Kubernetes cluster can reach.

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

This will create `distributor`, `compactor`, `ingester`, `querier` and `query-frontend` components.

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

This will create `distributor`, `compactor`, `ingester`, `querier` and `query-frontend` components.

## Loki Operator on Openshift
Loki operator on Openshift will allow you to configure [gateway](https://github.com/observatorium/api) for loki multi-tenancy & authentication

### Requirements
- Install oc CLI for communicating with the cluster.
- Running Openshift cluster with a valid certificate for dex route.
- A container registry that you and your openshift cluster can reach.

### Setup
Since loki-operator is not already available on operator hub, you will need to build it from sources for now

Clone loki-operator repository and deploy
```bash
git clone https://github.com/ViaQ/loki-operator.git
cd loki-operator
make olm-deploy REGISTRY_ORG=$YOUR_QUAY_ORG VERSION=$VERSION
```

Create aws bucket and secret. You can check [deploy-example-secret.sh](https://github.com/ViaQ/loki-operator/blob/master/hack/deploy-example-secret.sh) for infos.
Example with us-east-1 region for netobserv-loki bucket:
```bash
aws s3api create-bucket --bucket netobserv-loki --region us-east-1
oc -n openshift-logging create secret generic test --from-literal=endpoint="https://s3.us-east-1.amazonaws.com" --from-literal=region="eu-east-1" --from-literal=bucketnames="netobserv-loki" --from-literal=access_key_id="XXXXXXXXXXXXXXXXXXXX" --from-literal=access_key_secret="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

Create LokiStack instance
Open your Openshift Administrator Console and go to:
    Installed Operators => Openshift Loki Operator (in openshift-logging namespace) 
    Click on `Create instance` in LokiStacks card
    Copy / Paste `hack/lokistack_gateway_dev.yaml` content from sources to YAML tab and update it if needed

This will create `distributor`, `compactor`, `ingester`, `querier`, `query-frontend` and `lokistack-gateway` components.

### Troubleshooting
- Insuffisant CPU or Memory
If your pods hang in `Pending` state, you should double check their status using `oc describe`
We recommand to use size: 1x.extra-small but this still require a lot of ressources. 
You can decrese them in internal/manifests/internal/sizes.go and set `100m` for each CPUs and `256Mi` for each Memories

## Loki & Grafana stack with Helm

Deploy [loki and grafana](https://grafana.com/docs/loki/latest/installation/helm/#deploy-grafana-to-your-cluster) to your cluster from official images using helm
```bash
helm upgrade --install loki grafana/loki-stack --set promtail.enabled=false
helm install loki-grafana grafana/grafana
```

Wait for the service running then forward port
`kubectl port-forward service/loki-grafana 3000:80`

Login : `admin`
Password should be retreive with :
`kubectl get secret loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo`

### Troubleshooting
If loki-grafana deployment fails with following error on OpenShift:
Error creating: pods "loki-grafana-XXXXXXXXXX" is forbidden: unable to validate against any security context

Simply run:
```bash
oc adm policy add-scc-to-user anyuid -z loki
oc adm policy add-scc-to-user anyuid -z loki-grafana
```

## Grafana
If you installed loki using the operator, you will not have grafana installed. You may need to install it to make queries and dashboards but it's not mandatory to make loki work.

### From Image

Create [grafana instance](https://grafana.com/docs/grafana/latest/installation/kubernetes/) from official image
`kubectl apply -f examples/grafana.yaml`

Wait for the service running then forward port
`kubectl port-forward service/grafana 3000:3000`

Login : `admin`
Password : `admin`
Info : You can skip password definition or change it at first login

### From Openshift OperatorHub
Grafana operator is available on OperatorHub. Open your Openshift Administrator Console and go to:
    Operators -> OperatorHub
    Search for 'grafana'
    Install it using default options in default namespace for example
    *This can take some minutes*

Then go to:
    Operators -> Installed Operators
    Select grafana-operator
    Click on `Create Instance` in the Grafana Provided API card
    *This can take some minutes*

This will create a grafana instance with a route available in:
    Networking -> Routes

Login : `root`
Password : `secret`

You can follow this [blog post](https://www.redhat.com/en/blog/custom-grafana-dashboards-red-hat-openshift-container-platform-4) for more details

## Grafana Usage

Open http://localhost:3000/ and login with `admin` + password according to previous sections

Select "add datasource" => "Loki" and set your source :
- `http://loki:3100` for helm
- `http://loki-query-frontend-http-lokistack-dev.default.svc.cluster.local:3100` for loki-operator without gateway
- `YOUR_GATEWAY_ROUTE/api/logs/v1/tenant-a` for loki-operator with gateway enabled using `tenant-a` endpoint

You should get "Data source connected and labels found." after clicking Save & Test button

Example of queries:
- View raw logs:
`{app="goflow2"}`

- Top 10 sources by volumetry (1 min-rate):
`topk(10, (sum by(SrcWorkload,SrcNamespace) ( rate({ app="goflow2" } | json | __error__="" | unwrap Bytes [1m]) )))`

- Top 10 destinations for a given source (1 min-rate):
`topk(10, (sum by(DstWorkload,DstNamespace) ( rate({ app="goflow2",SrcNamespace="default",SrcWorkload="goflow" } | json | __error__="" | unwrap Bytes [1m]) )))`