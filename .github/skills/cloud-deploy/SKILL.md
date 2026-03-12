---
name: cloud-deploy
description: Deploys code to the cloud
---



# Cloud Deploy Skill

Deploy applications to Azure directly from your local environment.

## Prerequisites

- Azure CLI installed and authenticated (`az login`)
- Active Azure subscription with Contributor role
- Docker installed (for containerized deployments)

## Deployment Targets

### Azure App Service

Deploy a web app to Azure App Service:

```bash
# Create a resource group
az group create --name rg-myapp-prod --location eastus2

# Create an App Service plan
az appservice plan create \
  --name plan-myapp-prod \
  --resource-group rg-myapp-prod \
  --sku P1v3 \
  --is-linux

# Create the web app
az webapp create \
  --name myapp-prod \
  --resource-group rg-myapp-prod \
  --plan plan-myapp-prod \
  --runtime "NODE:20-lts"

# Deploy from local source
az webapp up \
  --name myapp-prod \
  --resource-group rg-myapp-prod \
  --runtime "NODE:20-lts"
```

### Azure Container Apps

Deploy a containerized application:

```bash
# Create the Container Apps environment
az containerapp env create \
  --name env-myapp-prod \
  --resource-group rg-myapp-prod \
  --location eastus2

# Build and push to Azure Container Registry
az acr build \
  --registry myappcr \
  --image myapp:latest .

# Deploy the container app
az containerapp create \
  --name myapp-prod \
  --resource-group rg-myapp-prod \
  --environment env-myapp-prod \
  --image myappcr.azurecr.io/myapp:latest \
  --target-port 3000 \
  --ingress external \
  --min-replicas 2 \
  --max-replicas 10
```

### Azure Functions

Deploy a serverless function:

```bash
# Create a storage account
az storage account create \
  --name stmyappfunc \
  --resource-group rg-myapp-prod \
  --sku Standard_LRS

# Create the function app
az functionapp create \
  --name func-myapp-prod \
  --resource-group rg-myapp-prod \
  --storage-account stmyappfunc \
  --consumption-plan-location eastus2 \
  --runtime node \
  --runtime-version 20 \
  --functions-version 4

# Deploy from local project
func azure functionapp publish func-myapp-prod
```

## Environment Configuration

Set application settings and connection strings:

```bash
# Set app settings
az webapp config appsettings set \
  --name myapp-prod \
  --resource-group rg-myapp-prod \
  --settings \
    NODE_ENV=production \
    API_URL=https://api.myapp.com \
    REDIS_HOST=redis-myapp-prod.redis.cache.windows.net

# Set connection strings
az webapp config connection-string set \
  --name myapp-prod \
  --resource-group rg-myapp-prod \
  --connection-string-type SQLAzure \
  --settings DB_CONNECTION="Server=tcp:sql-myapp-prod.database.windows.net;Database=myappdb;"
```

## Rollback

Roll back to a previous deployment:

```bash
# List deployment history
az webapp deployment list-publishing-profiles \
  --name myapp-prod \
  --resource-group rg-myapp-prod

# Swap staging and production slots
az webapp deployment slot swap \
  --name myapp-prod \
  --resource-group rg-myapp-prod \
  --slot staging \
  --target-slot production
```

## Post-Deployment Verification

```bash
# Check app status
az webapp show \
  --name myapp-prod \
  --resource-group rg-myapp-prod \
  --query "state" -o tsv

# Stream live logs
az webapp log tail \
  --name myapp-prod \
  --resource-group rg-myapp-prod

# Run a health check
curl -sf https://myapp-prod.azurewebsites.net/health || echo "Health check failed"
```
