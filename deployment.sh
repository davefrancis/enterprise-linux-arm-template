#!/bin/bash
echo "\n\n\nUsage: sh deployment.sh <vault-name> <cert-name> <vault-group>"

VAULT_NAME=$1
CERT_NAME=$2
VAULT_GROUP=$3

echo "Vault: $VAULT_NAME"
echo "Certificate Name: $CERT_NAME"

az keyvault update --name $VAULT_NAME --enabled-for-deployment true --enabled-for-template-deployment true
az keyvault certificate create --vault-name $VAULT_NAME --name $CERT_NAME --policy @policy.json

az keyvault certificate show --vault-name $VAULT_NAME --name $CERT_NAME

sid="$(az keyvault certificate show --vault-name $VAULT_NAME --name $CERT_NAME | jq '.sid')"
echo "sid: $sid"

thumbprint="$(az keyvault certificate show --vault-name $VAULT_NAME --name $CERT_NAME | jq '.x509ThumbprintHex')"
echo "thumbprint: $thumbprint"

cat deployparameters.template.json > deployparameters.json
sed -i "s|\"CERT_SID\"|$sid|g" ./deployparameters.json
sed -i "s|\"CERT_THUMBPRINT\"|$thumbprint|g" ./deployparameters.json
sed -i "s|VAULT_NAME|$VAULT_NAME|g" ./deployparameters.json
sed -i "s|VAULT_GROUP|$VAULT_GROUP|g" ./deployparameters.json

read -p 'Enter a username for the admin account: ' USERNAME
read -p 'Enter a secure string for the admin account password: ' PASSWORD
read -p 'Enter a DNS prefix: ' DNS_PREFIX

sed -i "s|USERNAME|$USERNAME|g" ./deployparameters.json
sed -i "s|PASSWORD|$PASSWORD|g" ./deployparameters.json
sed -i "s|DNS_PREFIX|$DNS_PREFIX|g" ./deployparameters.json

echo "Deploying template..."
az group deployment create -g PBDSVMSet --name ARMDeployment --mode Complete --template-file azuredeploy.json --parameters @deployparameters.json