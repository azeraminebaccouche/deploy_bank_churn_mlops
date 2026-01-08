#!/bin/bash
set -e

# --- CONFIGURATION ---
RESOURCE_GROUP="rg-mlops-student"
LOCATION="francecentral"
FALLBACK_LOCATION="norwayeast"
ACR_NAME="acr$(date +%s)"
APP_NAME="bank-churn-api"
ENV_NAME="env-mlops-student"

echo "🚀 DÉMARRAGE DU DÉPLOIEMENT (REPRISE)..."

# 1. Groupe de Ressources (déjà fait, mais on vérifie)
echo "--- Étape 1/5 : Validation Groupe de Ressources ---"
az group create -n "$RESOURCE_GROUP" -l "$LOCATION" -o none || true

# 2. ACR (déjà fait, on récupère juste le nom existant si possible)
echo "--- Étape 2/5 : Validation Registry ---"
# On essaie de récupérer l'ACR existant s'il a été créé avant
EXISTING_ACR=$(az acr list -g "$RESOURCE_GROUP" --query "[0].name" -o tsv 2>/dev/null || echo "")

if [ -n "$EXISTING_ACR" ]; then
    ACR_NAME=$EXISTING_ACR
    echo "✅ ACR existant trouvé : $ACR_NAME"
else
    # Sinon on le crée (logique de fallback)
    set +e
    az acr create -g "$RESOURCE_GROUP" -n "$ACR_NAME" --sku Basic --admin-enabled true -l "$LOCATION" -o none 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "⚠️  Région bloquée. Fallback vers $FALLBACK_LOCATION..."
        LOCATION="$FALLBACK_LOCATION"
        az group create -n "$RESOURCE_GROUP" -l "$LOCATION" -o none || true
        set -e
        az acr create -g "$RESOURCE_GROUP" -n "$ACR_NAME" --sku Basic --admin-enabled true -l "$LOCATION" -o none
    fi
    set -e
    echo "✅ ACR créé : $ACR_NAME"
fi

# 3. Build & Push
echo "--- Étape 3/5 : Construction Docker ---"
az acr login -n "$ACR_NAME"
SERVER=$(az acr show -n "$ACR_NAME" --query loginServer -o tsv | tr -d '\r')

echo "Construction et envoi de l'image..."
docker build --platform linux/amd64 -t "$SERVER/$APP_NAME:v1" .
docker push "$SERVER/$APP_NAME:v1"

# 4. Environnement
echo "--- Étape 4/5 : Environnement Container Apps ---"
az provider register -n Microsoft.App --wait
az containerapp env create -n "$ENV_NAME" -g "$RESOURCE_GROUP" -l "$LOCATION" -o none

# 5. Déploiement
echo "--- Étape 5/5 : Déploiement API ---"
USER=$(az acr credential show -n "$ACR_NAME" --query username -o tsv | tr -d '\r')
PASS=$(az acr credential show -n "$ACR_NAME" --query "passwords[0].value" -o tsv | tr -d '\r')

az containerapp create \
  -n "$APP_NAME" \
  -g "$RESOURCE_GROUP" \
  --environment "$ENV_NAME" \
  --image "$SERVER/$APP_NAME:v1" \
  --registry-server "$SERVER" \
  --registry-username "$USER" \
  --registry-password "$PASS" \
  --ingress external \
  --target-port 8000 \
  --cpu 0.25 --memory 0.5Gi \
  --min-replicas 1 --max-replicas 1 \
  -o none

URL=$(az containerapp show -n "$APP_NAME" -g "$RESOURCE_GROUP" --query properties.configuration.ingress.fqdn -o tsv | tr -d '\r')

echo ""
echo "=================================================="
echo "🎉 SUCCESS !"
echo "API URL : https://$URL"
echo "Docs    : https://$URL/docs"
echo "=================================================="
