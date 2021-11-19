# Hacks on Dex
This hack works on Openshift using openshift-install CLI tool with [custom install config](https://docs.openshift.com/container-platform/4.1/installing/installing_aws/installing-aws-customizations.html#installation-initializing_install-customizations-cloud)

You can skip certificate creation if you already have a valid certificate for your dex route.

## ZeroSSL.com CA with acme.sh
In order to use DEX, you will need a valid trusted SSL certificat. 
If you are using `openshift-install` cli on aws you can use [acme.sh](https://github.com/acmesh-official/acme.sh/wiki/ZeroSSL.com-CA)

Clone acms.sh repository:
```bash
git clone https://github.com/acmesh-official/acme.sh.git
cd acme.sh
```
Register your account:
```bash
./acme.sh  --register-account  -m myemail@example.com --server zerossl
```

Create certificates for your current instance:
```bash
export API=$(oc whoami --show-server | cut -f 2 -d ':' | cut -f 3 -d '/' | sed 's/-api././')
export WILDCARD=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.status.domain}')
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key) AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id) ./acme.sh  --issue   --dns dns_aws -d ${API} -d *.${WILDCARD}
```
You will get a list of certificates with path at the end of this bash. Replace `/path/to/fullchain.cer` and `/path/to/api.key` in the next commands.

Update ingress default certificate:
```bash
oc create secret tls router-certs --cert=/path/to/fullchain.cer --key=/path/to/api.key -n openshift-ingress
oc patch ingresscontroller default -n openshift-ingress-operator --type=merge --patch='{"spec": { "defaultCertificate": { "name": "router-certs" } } }'
```

Update api certificate:
```bash
oc create secret tls api-certs --cert=/path/to/fullchain.cer --key=/path/to/api.key -n openshift-config
oc patch apiserver cluster \
     --type=merge -p \
     "{\"spec\":{\"servingCerts\": {\"namedCertificates\": [{\"names\": [\"${API}\"], \"servingCertificate\": {\"name\": \"api-certs\"}}]}}}"
```

## Create dex instance
Replace all `<MY_CLUSTER_URL>` occurences in `examples/dex.yaml`.

Copy your `api.XXX.cer` content to `certificate`, `api.XXX.key` content to `key` and `ca.cer` to `caCertificate` in Route tls specs in `examples/dex.yaml`

Create dex instance in openshift-logging namespace:
```bash
oc create namespace openshift-logging
oc apply -f examples/dex.yaml
```