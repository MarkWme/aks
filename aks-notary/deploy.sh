#!/bin/zsh

# Install the notation CLI
# Note: This installation is for macOS on ARM64 (Apple Silicon)

curl -Lo notation.tar.gz https://github.com/notaryproject/notation/releases/download/v1.0.0-rc.2/notation_1.0.0-rc.2_darwin_arm64.tar.gz
sudo tar xvzf notation.tar.gz -C /usr/local/bin/ notation

# Install the notation plugin for Azure Key Vault

mkdir -p ~/Library/Application\ Support/notation/plugins/azure-kv
curl -Lo notation-azure-kv.tar.gz https://github.com/Azure/notation-azure-kv/releases/download/v0.5.0-rc.1/notation-azure-kv_0.5.0-rc.1_Darwin_arm64.tar.gz
tar xvzf notation-azure-kv.tar.gz -C ~/.config/notation/plugins/azure-kv notation-azure-kv
tar xvzf notation-azure-kv.tar.gz -C ~/Library/Application\ Support/notation/plugins/azure-kv notation-azure-kv

# Optionally run the following command to verify the installation
notation plugin ls

AKV_NAME=msazuredev
KEY_NAME=msazuredev
CERT_SUBJECT="CN=msazure.dev,O=Notary,L=Seattle,ST=WA,C=US"
CERT_PATH=./${KEY_NAME}.pem

ACR_NAME=msazuredev
REGISTRY=$ACR_NAME.azurecr.io
REPO=net-monitor
TAG=v1
IMAGE=$REGISTRY/${REPO}:$TAG
IMAGE_SOURCE=https://github.com/wabbit-networks/net-monitor.git#main

cat <<EOF > ./my_policy.json
{
    "issuerParameters": {
    "certificateTransparency": null,
    "name": "Self"
    },
    "x509CertificateProperties": {
    "ekus": [
        "1.3.6.1.5.5.7.3.3"
    ],
    "keyUsage": [
        "digitalSignature"
    ],
    "subject": "$CERT_SUBJECT",
    "validityInMonths": 12
    }
}
EOF

az keyvault certificate create -n $KEY_NAME --vault-name $AKV_NAME -p @my_policy.json
KEY_ID=$(az keyvault certificate show -n $KEY_NAME --vault-name $AKV_NAME --query 'kid' -o tsv)
CERT_ID=$(az keyvault certificate show -n $KEY_NAME --vault-name $AKV_NAME --query 'id' -o tsv)
az keyvault certificate download --file $CERT_PATH --id $CERT_ID --encoding PEM
notation key add $KEY_NAME --plugin azure-kv --id $KEY_ID

notation key ls

STORE_TYPE="ca"
STORE_NAME="msazure.dev"
notation cert add --type $STORE_TYPE --store $STORE_NAME $CERT_PATH

notation cert ls

az acr build -r $ACR_NAME -t $IMAGE $IMAGE_SOURCE

# Note - the below value is correct and will login with the current user. It is NOT a placeholder value!
export USER_NAME=00000000-0000-0000-0000-000000000000
export PASSWORD=$(az acr login --name $ACR_NAME --expose-token --output tsv --query accessToken)
notation login -u $USER_NAME -p $PASSWORD $REGISTRY

# If this next step fails, check that your currently signed in user has 'sign' permission on the key vault.
notation sign --signature-format cose --key $KEY_NAME $IMAGE

notation ls $IMAGE

az acr manifest show-metadata $IMAGE -o jsonc

# Verify the image

cat <<EOF > ~/Library/Application\ Support/notation/trustpolicy.json
{
    "version": "1.0",
    "trustPolicies": [
        {
            "name": "msazuredev-images",
            "registryScopes": [ "$REGISTRY/$REPO" ],
            "signatureVerification": {
                "level" : "strict" 
            },
            "trustStores": [ "$STORE_TYPE:$STORE_NAME" ],
            "trustedIdentities": [
                "x509.subject: $CERT_SUBJECT"
            ]
        }
    ]
}
EOF

notation verify $IMAGE

# ----
# Stop here!
#
# Create Azure resources
#
location=westeurope
#
# Choose random name for resources
#
name=aks-$(cat /dev/urandom | base64 | tr -dc '[:lower:]' | fold -w ${1:-5} | head -n 1) 2> /dev/null
#
# Calculate next available network address space
#
number=0
number=$(az network vnet list --query "[].addressSpace.addressPrefixes" -o tsv | cut -d . -f 2 | sort | tail -n 1)
if [[ -z $number ]]
then
    number=0
fi
networkNumber=$(expr $number + 1)
virtualNetworkPrefix=10.${networkNumber}.0.0/16
aksSubnetPrefix=10.${networkNumber}.0.0/24
#
# Get current latest (preview) version of Kubernetes
#
version=$(az aks get-versions -l $location --query "orchestrators[-1].orchestratorVersion" -o tsv)  2>/dev/null
#
# Create resource group
#
az group create -n $name -l $location

az deployment group create \
    -n $name-$RANDOM \
    -g $name \
    -f ./bicep/main.bicep \
    --parameters \
        name=$name \
        networkNumber=$networkNumber \
        kubernetesVersion=$version \
    -o table

# ---

# Test deployment of signed images with Ratify

# Install Gatekeeper

helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts

helm install gatekeeper/gatekeeper  \
    --name-template=gatekeeper \
    --namespace gatekeeper-system --create-namespace \
    --set enableExternalData=true \
    --set validatingWebhookTimeoutSeconds=5 \
    --set mutatingWebhookTimeoutSeconds=2

# Get public key

export PUBLIC_KEY=$(az keyvault certificate show -n $KEY_NAME \
                    --vault-name $AKV_NAME \
                    -o json | jq -r '.cer' | base64 -d | openssl x509 -inform DER)

# Install Ratify

# Ratify part of this is not working at present. Seems to be due to changes in Ratify that
# are not yet reflected in the Helm chart. Check on progress of the 0.6.0 release.

# https://github.com/Azure/notation-azure-kv/blob/main/docs/nv2-bicep.md
# https://github.com/Azure/notation-azure-kv/blob/main/docs/nv2-sign-verify-aks.md
# https://github.com/Azure/notation-azure-kv/issues/60

# Issues include:
# Ratify requires tls.cabundle to be set, sample scripts don't reflect this
# AKS cluster deploys gatekeeper automatically, but need newer version that supports mutation
# Automatic deployment of gatekeeper is probably due to Azure Defender policy configuration enforcing it

kubectl config set-context --current --namespace=default
helm repo add ratify https://deislabs.github.io/ratify
helm install ratify \
    ratify/ratify \
    --set ratifyTestCert="$PUBLIC_KEY"

# generate CA key and certificate
echo "Generating CA key and certificate for ratify..."
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 14 -key ca.key -subj "/O=Ratify/CN=Ratify Root CA" -out ca.crt

# generate server key and certificate
echo "Generating server key and certificate for ratify..."
openssl genrsa -out server.key 2048
openssl req -newkey rsa:2048 -nodes -keyout server.key -subj "/CN=ratify.${ns}" -out server.csr
openssl x509 -req -extfile <(printf "subjectAltName=DNS:ratify.${ns}") -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

curl -sSLO https://raw.githubusercontent.com/deislabs/ratify/main/test/testdata/notary.crt
helm install ratify \
    ratify/ratify --atomic \
    --namespace gatekeeper-system \
    --set-file notaryCert=./notary.crt


helm install ratify ratify/ratify \
    --set registryCredsSecret=regcred \
    --set ratifyTestCert=$PUBLIC_KEY \
    --set-file provider.tls.crt=server.crt \
    --set-file provider.tls.key=server.key \
    --set provider.tls.cabundle="$(cat ca.crt | base64 | tr -d '\n')"