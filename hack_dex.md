# Hacks on Dex

## Trusted cert using openshift-install command
Create ssl certificate using openssl:
`openssl req -x509 -newkey rsa:4096 -keyout ssl.key -out ssl.cert -sha256 -days 365`
Specify at least a correct hostname. You can use wildcards like `*.*.*.example.openshift.com` for example

Copy your ssl.cert content to `additionalTrustBundle` section at the bottom of `install-config.yaml` before running `openshift-install create cluster command`
```yaml
apiVersion: v1
...
additionalTrustBundle: | 
    -----BEGIN CERTIFICATE-----
    <MY_TRUSTED_CA_CERT>
    -----END CERTIFICATE-----
```

## Create dex instance

Replace all `<MY_CLUSTER_URL>` occurences in `examples/dex.yaml`
Copy your ssl.cert content to `certificate` and ssl.key content to `key` in Route tls specs in `examples/dex.yaml`

Create dex instance in openshift-logging namespace:
```bash
oc create namespace openshift-logging
oc apply -f examples/dex.yaml
```