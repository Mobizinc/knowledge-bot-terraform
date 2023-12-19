provider "azurerm" {
  features {}
}
data "azurerm_client_config" "current" {}


variable "resource_group_name" {
  description = "resource Group name"
  type        = string
}
variable "location" {
  description = "Location in which to deploy the resources"
  type        = string
}
variable "environment" {
  description = "environment"
  type        = string
}
variable "owner" {
  description = "Project Owner"
  type        = string
}
variable "project_code" {
  description = "Project Code"
  type        = string
}
variable "application_name" {
  description = "application_name"
  type        = string
  default     = "knowledge-bot"
}

variable "keyvault_name" {
  description = "keyvault name"
  type        = string
}

variable "keyvault_sku" {
  description = "keyvault sku"
  type        = string
}



#build azure resource group
resource "azurerm_resource_group" "knowledge-bot" {
    name = var.resource_group_name
    location = var.location
    tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}


resource "azurerm_storage_account" "knowledge-bot-sa" {
  name                      = "knowledgebotsa"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  account_kind              = "StorageV2"
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}


resource "azurerm_service_plan" "asp-knowledge-bot" {
  name                = "asp-knowledge-bot"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  os_type             = "Linux"
  sku_name            = "B3"
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}


resource "azurerm_user_assigned_identity" "mi-knowledge-bot" {

  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  name                        = "mi-knowledge-bot"
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}


resource "azurerm_application_insights" "kb-ai" {
  name                = "kb-backend-ai"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  application_type    = "web"
}

resource "azurerm_linux_web_app" "knowledge-bot-back-end" {
depends_on = [azurerm_user_assigned_identity.mi-knowledge-bot ] 
  name                        = "knowledge-bot-back-end"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  service_plan_id             = azurerm_service_plan.asp-knowledge-bot.id
  https_only                  = true
  app_settings = {
    WEBSITE_PYTHON_VERSION = "3.10"
    SCM_DO_BUILD_DURING_DEPLOYMENT =  "true"
        ACCESS_TOKEN_EXPIRES_IN             = "15" 
          AZURE_CLIENT_ID                     = "76ae1e67-c3d9-464d-b7f7-e5b89398e221" 
          AZURE_COGNITIVE_SEARCH_INDEX_NAME   = "mobizsalesindex" 
          AZURE_COGNITIVE_SEARCH_SERVICE_NAME = "https://knowledge-bot-basic-15.search.windows.net" 
          AZURE_TENANT_ID                     = "8bfe0e10-3213-49c3-ba07-719dee9fd10b" 
          BLOB_CONTAINER_NAME                 = "mobizsalesdocs"
          CLIENT_ORIGIN                       = "http://localhost:3000" 
          DOCUMENT_CHUNK_OVERLAP              = "100" 
          DOCUMENT_CHUNK_SIZE                 = "1000" 
          DOCUMENT_SOURCE_DIRECTORY           = "HR" 
          INDEX_DOCUMENT                      = "False" 
          JWT_ALGORITHM                       = "HS256" 
          LANGCHAIN_API_KEY                   = "ls__8ac8b824b49c41a6b9f841913de6b998" 
          LANGCHAIN_PROJECT                   = "pt-knowledge-bot-mobiz" 
          OPENAI_API_BASE                     = "https://azure-chatbot-openai.openai.azure.com/" 
          OPENAI_API_KEY                      = "fb9d9eaaf03c46629022499658423536" 
          OPENAI_API_VERSION                  = "2023-05-15"
          POSTGRES_DB                         = "apollo" 
          POSTGRES_HOST                       = "azure-chatbot-sql.database.windows.net" 
          POSTGRES_HOSTNAME                   = "azure-chatbot-sql.database.windows.net" 
          POSTGRES_PASSWORD                   = "9aX!7rP^2oL8t3Y0z" 
          POSTGRES_USER                       = "muhammad.ayaz" 
          REDIS_CACHE_HOST                    = "mobizassistant.redis.cache.windows.net" 
          REDIS_CACHE_PORT                    = "6380" 
          REFRESH_TOKEN_EXPIRES_IN            = "60" 
          SEARCH_API_VERSION                  = "2023-07-01-Preview" 
          SEARCH_SERVICE_NAME                 = "knowledge-bot-basic-15" 
          SECOND_DB                           = "apollo" 
          SECRET_KEY                          = "supersecretljfdl283894839jlddfk" 
          STORAGE_ACCOUNT_NAME                = "asanofibotsdemo85dd" 
          STORAGE_CONNECTION_STRING           = "DefaultEndpointsProtocol=https;AccountName=asanofibotsdemo85dd;AccountKey=***;EndpointSuffix=core.windows.net\"" 
          UPLOAD_DOCUMENTS                    = "False" 
    
  }
  identity {
           identity_ids = [azurerm_user_assigned_identity.mi-knowledge-bot.id]
           type         = "UserAssigned" 
        }
  key_vault_reference_identity_id = azurerm_user_assigned_identity.mi-knowledge-bot.id    
  site_config {
     always_on                              = true
     vnet_route_all_enabled                 = false
     app_command_line                       = "python -m uvicorn main:app --host 0.0.0.0" 
     application_stack  {
           python_version  = "3.10"
       
     }  
     cors {
               allowed_origins     = [
                   "http://localhost:3000",
                   "https://calm-grass-07517a20f.4.azurestaticapps.net",
                   "https://knowledge-bot-front-end-test.azurewebsites.net",
                   "https://knowledge.mobizinc.com",
                ] 
                support_credentials = true 
            }
  }
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
  lifecycle {
    ignore_changes = [
      app_settings,
    ]
  }
}



resource "azurerm_key_vault" "knowledge-bot_keyvault" {
  name                        = var.keyvault_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  sku_name                    = var.keyvault_sku
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
  
}

 resource "azurerm_key_vault_access_policy" "mi-knowledge-bot" {
   key_vault_id = azurerm_key_vault.knowledge-bot_keyvault.id
   tenant_id    = data.azurerm_client_config.current.tenant_id
   object_id    = azurerm_user_assigned_identity.mi-knowledge-bot.principal_id
   secret_permissions = [
     "Get"
   ]
 }

resource "azurerm_redis_cache" "knowledge-bot" {
  name                = "knowledge-bot"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}

resource "azurerm_static_site" "knowledge-bot" {
  name                = "knowledge-bot-front-end"
  location                    = "eastus2"
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}

resource "azurerm_linux_web_app" "knowledge-bot-front-end" {
  app_settings = {
    APPLICATIONINSIGHTS_CONNECTION_STRING      = "InstrumentationKey=0c8adbc4-e472-4d89-b3cc-cd06a52a6b6d;IngestionEndpoint=https://eastus-8.in.applicationinsights.azure.com/;LiveEndpoint=https://eastus.livediagnostics.monitor.azure.com/"
    AZURE_AD_CLIENT_ID                         = "76ae1e67-c3d9-464d-b7f7-e5b89398e221"
    AZURE_AD_TENANT_ID                         = "organizations"
    ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
    NEXTAUTH_SECRET                            = "ZmPyZU/WBIa4oATeVrDnm/ZDnAq8dzVLtrbZZRcoMRg="
    NEXTAUTH_URL                               = "https://knowledge.mobizinc.com"
    NEXT_PUBLIC_API_URL                        = "https://knowledge-bot-back-end.azurewebsites.net"
    SCM_DO_BUILD_DURING_DEPLOYMENT             = "true"
    WEBSITE_NODE_DEFAULT_VERSION               = "18-lts"
    XDT_MicrosoftApplicationInsights_Mode      = "default"
  }
  https_only                  = true
  name                        = "knowledge-bot-front-end-test"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  service_plan_id             = azurerm_service_plan.asp-knowledge-bot.id
  tags = {
    Environment  = "Dev"
    Owner        = "wobeidy@mobizinc.com"
    Project_Code = "prj-knowledge-bot"
  }

  site_config {
    always_on                                     = true
    application_stack {
      node_version             = "18-lts"
    }
  }
  lifecycle {
    ignore_changes = [
      app_settings
    ]
  }
}

resource "azurerm_service_plan" "knowledge-bot-logic-app" {
  name                        = "asp-knowledge-bot-logic-app"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  os_type             = "Windows"
  sku_name            = "WS1"

}

resource "azurerm_logic_app_standard" "knowledge-bot-la" {

  name                        = "knowledge-bot-la"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  app_service_plan_id         = azurerm_service_plan.knowledge-bot-logic-app.id
  storage_account_name        = azurerm_storage_account.knowledge-bot-sa.name
  storage_account_access_key  = azurerm_storage_account.knowledge-bot-sa.primary_access_key
  version                     = "4"
  identity {
      type         = "SystemAssigned" 
  }
}
