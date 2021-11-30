# Hacks on Loki & Grafana
This file will help you using [loki-operator](https://github.com/ViaQ/loki-operator) since it's still WIP project.
You can check [this PR](https://github.com/ViaQ/loki-operator/pull/99) for dev usage and the [README.md](https://github.com/ViaQ/loki-operator/blob/master/README.md) file for status

## Loki Operator without gateway
Loki operator can be run without gateway for debug on kind or Openshift. It will create the same ressources as helm lokistack installation:
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
```bash
sed -i 's/auth_enabled: true/auth_enabled: false/g' internal/manifests/internal/config/loki-config.yaml
```

Build and push the container image and then deploy the operator
```bash
make oci-build oci-push deploy REGISTRY_ORG=netobserv VERSION=latest
```

Create a LokiStack instance to get the various components of Loki up and running
```bash
kubectl apply -f hack/lokistack_dev.yaml
```

This will create `distributor`, `compactor`, `ingester`, `querier` and `query-frontend` components.

## Loki Operator on Openshift (WIP, gateway is [still unstable](https://github.com/ViaQ/loki-operator/pull/100/) and configuration may change)
Loki operator on Openshift will allow you to configure [gateway](https://github.com/observatorium/api) for loki multi-tenancy & authentication

Check [Docs](https://github.com/ViaQ/loki-operator/tree/master/docs)

### Requirements
- Install oc CLI for communicating with the cluster.
- Running Openshift cluster
- [Configured DEX](./hack_dex.md)
- A container registry that you and your openshift cluster can reach.

### Setup
Since loki-operator is not already available on operator hub, you will need to build it from sources for now.

Clone loki-operator repository and deploy
```bash
git clone https://github.com/ViaQ/loki-operator.git
cd loki-operator
make olm-deploy REGISTRY_ORG=$YOUR_QUAY_ORG VERSION=$VERSION
```

[Create DEX instance](https://github.com/netobserv/documents/blob/main/hack_dex.md#create-dex-instance) in the `openshift-logging` namespace 

Create aws bucket and secret. You can check [deploy-example-secret.sh](https://github.com/ViaQ/loki-operator/blob/master/hack/deploy-example-secret.sh) for infos.
Example with us-east-1 region for netobserv-loki bucket:
```bash
aws s3api create-bucket --bucket netobserv-loki --region us-east-1
oc -n openshift-logging create secret generic test --from-literal=endpoint="https://s3.us-east-1.amazonaws.com" --from-literal=region="us-east-1" --from-literal=bucketnames="netobserv-loki" --from-literal=access_key_id="XXXXXXXXXXXXXXXXXXXX" --from-literal=access_key_secret="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

If you want to use internal HTTP urls, remove `--with-cert-signing-service`, `--with-service-monitors` and `--with-tls-service-monitors` flags in `config/overlays/openshift/manager_run_flags_patch.yaml`. 
Your container spec should look like this :
```yaml
      containers:
        - name: manager
          args:
          - "--with-lokistack-gateway"
          - "--with-lokistack-gateway-route"
```
Else you will have to create reencrypt routes to access services.

Create tenant secret with cliendID, clientSecret and ca according to your dex configuration:
```bash
oc create -n openshift-logging secret generic tenant-a --from-literal=clientID="tenant-a"  --from-literal=clientSecret="password" --from-literal=issuerCAPath=""
```
`issuerCAPath` can be left empty if you want to use server default API CA file. Else use relative path in gateway pod.

Update `oidc secret name`, `issuerURL` and `redirectURL` routes in `hack/lokistack_gateway_dev.yaml`:
```yaml
    secret:
        name: tenant-a
    issuerURL: https://dex-openshift-logging.apps.<MY_CLUSTER_URL>/dex/
    redirectURL:  http://gateway-openshift-logging.apps.<MY_CLUSTER_URL>/oidc/tenant-a/callback
```
You can check `examples/lokistack_gateway.yaml` in this repository for a compatible configuration with static users created in `examples/dex.yaml`. 
`usernameClaim` will take dex email and `groupClaim` is empty since DEX staticPasswords doesn't support groups.
`subjects` users are taken from Openshift users matching with identities.

Create LokiStack instance with static mode:
```bash
oc -n openshift-logging apply -f hack/lokistack_gateway_dev.yaml
```

OR

Open your Openshift Administrator Console and go to:
    Installed Operators => Openshift Loki Operator (in openshift-logging namespace) 
    Click on `Create instance` in LokiStacks card
    Copy / Paste `hack/lokistack_gateway_dev.yaml` content from sources to YAML tab

This will create `distributor`, `compactor`, `ingester`, `querier`, `query-frontend` and `lokistack-gateway` components.

Create gateway and gateway-status routes:
```bash
oc -n openshift-logging apply -f examples/gateway_routes.yaml
```

Gateway status will be available at:
`http://gateway-status-openshift-logging.apps.<MY_CLUSTER_URL>`

Loki will now be exposed at `api/logs/v1/tenant-a`. You can now open a private navigation and try the following url in your browser:
`http://gateway-openshift-logging.apps.<MY_CLUSTER_URL>/api/logs/v1/tenant-a/loki/api/v1/labels`
You will be redirected to DEX login before accessing this resource. It should return `status "success"`

Check all available routes in [api/logs/v1/http.go](https://github.com/observatorium/api/blob/main/api/logs/v1/http.go#L132)

### Troubleshooting
- Logs are by default `--log.level=warn`. 
You can set `--log.level=debug` in `gateway.go` and `opa_openshift.go` to get more logs.

- AWS region not set for deploy-example-secret.sh
If `aws configure get region` returns blank, the shell will fail. 
You can force region using `aws configure --region us-east-1` for example.

- Insuffisant CPU or Memory
If your pods hang in `Pending` state, you should double check their status using `oc describe`
We recommand to use size: 1x.extra-small but this still require a lot of ressources. 
You can decrese them in internal/manifests/internal/sizes.go and set `100m` for each CPUs and `256Mi` for each Memories

- Certificate errors in Gateway logs
Check [ZeroSSL.com CA with acme.sh](./hack_dex.md#zerosslcom-ca-with-acmesh)

## Loki & Grafana stack with Helm

Deploy [loki and grafana](https://grafana.com/docs/loki/latest/installation/helm/#deploy-grafana-to-your-cluster) to your cluster from official images using helm
```bash
helm upgrade --install loki grafana/loki-stack --set promtail.enabled=false
helm install loki-grafana grafana/grafana
```

Wait for the service running then forward port
```bash
kubectl port-forward service/loki-grafana 3000:80
```

Login : `admin`
Password should be retreive with :
```bash
kubectl get secret loki-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

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

### From Image with oauth
Create [grafana instance](https://grafana.com/docs/grafana/latest/installation/kubernetes/) from official image.
Update `examples/grafana.ini` configuration and run:
```bash
kubectl create configmap grafana-config --from-file=examples/grafana.ini
kubectl apply -f examples/grafana.yaml
```

Wait for the service running then forward port
```bash
kubectl port-forward service/grafana 3000:3000
```

OR 

Use route at `http://grafana-default.apps.<MY_CLUSTER_URL>`

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
- `lokistack-gateway-http-lokistack-dev.openshift-logging.svc.cluster.local:8080/api/logs/v1/tenant-a` for loki-operator with gateway enabled using `tenant-a` endpoint. 
  Check `Forward Oauth Identity` option to send `X-Forwarded-User` according to [grafana.ini](./examples/grafana.ini)

You should get "Data source connected and labels found." after clicking Save & Test button

Example of queries:
- View raw logs:
`{app="goflow2"}`

- Top 10 sources by volumetry (1 min-rate):
`topk(10, (sum by(SrcWorkload,SrcNamespace) ( rate({ app="goflow2" } | json | __error__="" | unwrap Bytes [1m]) )))`

- Top 10 destinations for a given source (1 min-rate):
`topk(10, (sum by(DstWorkload,DstNamespace) ( rate({ app="goflow2",SrcNamespace="default",SrcWorkload="goflow" } | json | __error__="" | unwrap Bytes [1m]) )))`