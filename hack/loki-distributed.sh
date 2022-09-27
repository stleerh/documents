#!/bin/bash

if [[ "$#" -lt 1 || "$1" = "--help" ]]; then
	echo "Syntax: $0 S3_NAME AWS_REGION"
	echo ""
	echo "Create S3 bucket and configure Loki as per https://github.com/netobserv/documents/blob/main/loki_distributed.md"
	echo "You need to have the AWS CLI installed and configured."
	echo ""
	echo "  e.g: $0 yourname-loki eu-west-1"
	echo ""
	exit
fi

S3_NAME="$1"
AWS_REGION="$2"
AWS_KEY=$(aws configure get aws_access_key_id)
AWS_SECRET=$(aws configure get aws_secret_access_key)

aws s3api create-bucket --bucket $S3_NAME  --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION

export LOKI_STORE_NAME=s3
export LOKI_STORE="
        s3:
          s3: https://s3.${AWS_REGION}.amazonaws.com
          bucketnames: ${S3_NAME}
          region: ${AWS_REGION}
          access_key_id: \${ACCESS_KEY_ID}
          secret_access_key: \${SECRET_ACCESS_KEY}
          s3forcepathstyle: true"

NAMESPACE=netobserv

kubectl create namespace $NAMESPACE
cat examples/distributed-loki/1-prerequisites/secret.yaml \
	| sed -r "s/X{5,}/$AWS_KEY/" \
	| sed -r "s~Y{5,}~$AWS_SECRET~" \
	| kubectl apply -n $NAMESPACE -f -

envsubst < examples/distributed-loki/1-prerequisites/config.yaml | kubectl apply -n $NAMESPACE -f -
kubectl apply -n $NAMESPACE -f examples/distributed-loki/1-prerequisites/service-account.yaml
kubectl apply -n $NAMESPACE -f examples/distributed-loki/2-components/
kubectl apply -n $NAMESPACE -f examples/distributed-loki/3-services/

echo ""
echo "Deployment complete"
echo ""
echo "Configure FlowCollector Loki with:"
echo "    url: 'http://loki-distributed-distributor.${NAMESPACE}.svc.cluster.local:3100/'"
echo "    querierUrl: 'http://loki-distributed-query-frontend.${NAMESPACE}.svc.cluster.local:3100/'"
echo ""
echo "To delete all created Kube resources, run:"
echo "kubectl delete -n $NAMESPACE --recursive -f examples/distributed-loki"
echo ""
echo "To delete the S3 bucket, run:"
echo "aws s3 rm s3://$S3_NAME --recursive"
echo "aws s3 rb s3://$S3_NAME"
