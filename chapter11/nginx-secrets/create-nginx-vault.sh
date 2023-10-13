#!/bin/bash
clear

tput setaf 5
echo -e "\n \n*******************************************************************************************************************"
echo -e "Creating namespace and ServiceAccount"
echo -e "*******************************************************************************************************************"
tput setaf 3
kubectl create ns my-ext-secret
kubectl create sa ext-secret-vault -n my-ext-secret

tput setaf 5
echo -e "\n \n*******************************************************************************************************************"
echo -e "Creating Vault secret and capabilities"
echo -e "*******************************************************************************************************************"
tput setaf 3

. ../vault_cli.sh

vault kv put secret/data/extsecret/config some-password=mysupersecretp@ssw0rd

vault policy write extsecret - <<EOF
path "secret/data/extsecret/config" {
  capabilities = ["read"]
}

path "secret/data/extsecret/config/*" {
  capabilities = ["read"]
}
EOF


vault write auth/kubernetes/role/extsecret \
     bound_service_account_names=ext-secret-vault \
     bound_service_account_namespaces=my-ext-secret \
     policies=extsecret \
     ttl=24h


tput setaf 5
echo -e "\n \n*******************************************************************************************************************"
echo -e "Deploying new NGINX image that uses a Vault secret"
echo -e "*******************************************************************************************************************"
tput setaf 3
export hostip=$(hostname  -I | cut -f1 -d' ' | sed 's/[.]/-/g')
sed "s/IPADDR/$hostip/g" < ./nginx-secrets.yaml  > /tmp/nginx-secrets.yaml
kubectl apply -f /tmp/nginx-secrets.yaml
echo -e "\n\n"
