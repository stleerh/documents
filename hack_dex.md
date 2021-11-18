# Hacks on Dex
This hack works on Openshift using openshift-install CLI tool with [custom install config](https://docs.openshift.com/container-platform/4.1/installing/installing_aws/installing-aws-customizations.html#installation-initializing_install-customizations-cloud)

You can skip certificate creation if you already have a valid wildcard certificate for your dex route.

## Create Certificate Authority
Create autosigned directories and certificate from `autosigned.conf` file
```bash
cd examples/ca
mkdir autosigned autosigned/certs autosigned/crl autosigned/private
touch autosigned/serial
echo "01" > autosigned/serial
touch autosigned/index.txt
OPENSSL=autosigned.conf openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -out autosigned/certs/ca.pem -outform PEM -keyout ./autosigned/private/ca.key
```

## Create new certificate request
Create certificate using openssl:
```bash
openssl req -newkey rsa:2048 -nodes -sha256 -keyout cert.key -keyform PEM -out cert.req -outform PEM
```

## Sign certificate with CA
Edit `v3.ext` file and update `subjectAltName` to match to your DNS. You can use wildcards here.

Sign certificate with custom CA and subjectAltName and check it:
```bash
OPENSSL_CONF=autosigned.conf openssl ca -batch -notext -in cert.req -out cert.pem -extfile v3.ext
openssl x509 -in cert.pem -noout -text
```

## Create dex instance
Replace all `<MY_CLUSTER_URL>` occurences in `examples/dex.yaml`

Copy your `cert.pem` content to `certificate`, `cert.key` content to `key` in Route tls specs in `examples/dex.yaml`

Create dex instance in openshift-logging namespace:
```bash
oc create namespace openshift-logging
oc apply -f examples/dex.yaml
```

## Patch Loki Operator Deployment
If you deployed your loki-operator and get `x509: certificate signed by unknown authority error` in gateway logs, you will need to inject your custom CA from a configmap.

Mount custom certificate created in gateway:
```bash
oc create configmap custom-ca --from-file=ca-bundle.crt=autosigned/certs/ca.pem -n openshift-logging
oc annotate configmap custom-ca service.beta.openshift.io/inject-cabundle=true -n openshift-logging
oc patch deployment.apps/lokistack-gateway-lokistack-dev --type merge --patch "$(cat examples/gatewayPatch.yaml)" -n openshift-logging
```