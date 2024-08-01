#!/bin/sh

kubectl create namespace azwi-qs-ns

# environment variables for the Azure Key Vault resource
export KEYVAULT_NAME="azwi-kv-quickstart"
export KEYVAULT_SECRET_NAME="my-secret"
export RESOURCE_GROUP="azwi-quickstart"
export LOCATION="uksouth"

# environment variables for the user-assigned managed identity
export USER_ASSIGNED_IDENTITY_NAME="azwi-identity-quickstart"

# environment variables for the Kubernetes service account & federated identity credential
export SERVICE_ACCOUNT_NAMESPACE="azwi-qs-ns"
export SERVICE_ACCOUNT_NAME="workload-identity-sa"
export SERVICE_ACCOUNT_ISSUER=$(az aks show --name aks-zmoep --resource-group aks-zmoep --query "oidcIssuerProfile.issuerUrl" -o tsv)

# az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}"

# az keyvault create --resource-group "${RESOURCE_GROUP}" \
#    --location "${LOCATION}" \
#    --name "${KEYVAULT_NAME}"

# az keyvault secret set --vault-name "${KEYVAULT_NAME}" \
#    --name "${KEYVAULT_SECRET_NAME}" \
#    --value "Hello\!"

# create a user-assigned managed identity if using user-assigned managed identity for this tutorial
# az identity create --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}"

export USER_ASSIGNED_IDENTITY_CLIENT_ID="$(az identity show --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --query 'clientId' -otsv)"
export USER_ASSIGNED_IDENTITY_OBJECT_ID="$(az identity show --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --query 'principalId' -otsv)"
# az keyvault set-policy --name "${KEYVAULT_NAME}" \
#   --secret-permissions get \
#   --object-id "${USER_ASSIGNED_IDENTITY_OBJECT_ID}"

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${APPLICATION_CLIENT_ID:-$USER_ASSIGNED_IDENTITY_CLIENT_ID}
  name: ${SERVICE_ACCOUNT_NAME}
  namespace: ${SERVICE_ACCOUNT_NAMESPACE}
EOF

az identity federated-credential create \
  --name "kubernetes-federated-credential" \
  --identity-name "${USER_ASSIGNED_IDENTITY_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --issuer "${SERVICE_ACCOUNT_ISSUER}" \
  --subject "system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}"

# echo "Waiting for federated credential to propagate..."
sleep 10

export KEYVAULT_URL="$(az keyvault show -g ${RESOURCE_GROUP} -n ${KEYVAULT_NAME} --query properties.vaultUri -o tsv)"
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: quick-start
  namespace: ${SERVICE_ACCOUNT_NAMESPACE}
  labels:
    azure.workload.identity/use: "true"
    app: "quick-start"
spec:
  serviceAccountName: ${SERVICE_ACCOUNT_NAME}
  containers:
    - image: ghcr.io/azure/azure-workload-identity/msal-go
      name: oidc
      env:
      - name: KEYVAULT_URL
        value: ${KEYVAULT_URL}
      - name: SECRET_NAME
        value: ${KEYVAULT_SECRET_NAME}
  nodeSelector:
    kubernetes.io/os: linux
EOF
