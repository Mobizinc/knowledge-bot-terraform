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

variable "storage_account_name" {
  description = "Storage account name"
  type        = string
}

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
  name                      = var.storage_account_name
  location                  = azurerm_resource_group.knowledge-bot.location
  resource_group_name       = azurerm_resource_group.knowledge-bot.name
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
  name                = "asp-${var.project_code}-${lower(var.environment)}"
  location            = azurerm_resource_group.knowledge-bot.location
  resource_group_name = azurerm_resource_group.knowledge-bot.name
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
  name                        = "mi-${var.project_code}-${lower(var.environment)}"
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}


resource "azurerm_application_insights" "kb-ai" {
  name                = "ai-backend-${var.project_code}-${lower(var.environment)}"
  location            = azurerm_resource_group.knowledge-bot.location
  resource_group_name = azurerm_resource_group.knowledge-bot.name
  application_type    = "web"
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}


resource "azurerm_linux_web_app" "knowledge-bot-back-end" {
depends_on = [azurerm_user_assigned_identity.mi-knowledge-bot ] 
  name                        = "${var.project_code}-${lower(var.environment)}-backend"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  service_plan_id             = azurerm_service_plan.asp-knowledge-bot.id
  https_only                  = true
  app_settings = {
          WEBSITE_PYTHON_VERSION              = "3.10"
          SCM_DO_BUILD_DURING_DEPLOYMENT      =  "true"
 
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
                   "https://knowledge-bot-test-frontend.azurewebsites.net",
           
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
  name                = "${var.project_code}-${lower(var.environment)}-redis"
  location            = azurerm_resource_group.knowledge-bot.location
  resource_group_name =  azurerm_resource_group.knowledge-bot.name
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



resource "azurerm_linux_web_app" "knowledge-bot-front-end" {
  app_settings = {
    SCM_DO_BUILD_DURING_DEPLOYMENT             = "true"
    WEBSITE_NODE_DEFAULT_VERSION               = "18-lts"

  }
  https_only                  = true
  name                        = "${var.project_code}-${lower(var.environment)}-frontend"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  service_plan_id             = azurerm_service_plan.asp-knowledge-bot.id
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
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
  name                        = "asp-${var.project_code}-${lower(var.environment)}-logic-app"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  os_type             = "Windows"
  sku_name            = "WS1"
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }

}

resource "azurerm_logic_app_standard" "knowledge-bot-la" {

  name                        = "${var.project_code}-${lower(var.environment)}-la"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  app_service_plan_id         = azurerm_service_plan.knowledge-bot-logic-app.id
  storage_account_name        = azurerm_storage_account.knowledge-bot-sa.name
  storage_account_access_key  = azurerm_storage_account.knowledge-bot-sa.primary_access_key
  version                     = "4"
  identity {
      type         = "SystemAssigned" 
  }
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}


resource "azurerm_linux_function_app" "kb-blobtrigger" {
  name                       = "${var.project_code}-${lower(var.environment)}-blobtrigger"
  location                   = azurerm_resource_group.knowledge-bot.location
  resource_group_name        = azurerm_resource_group.knowledge-bot.name
  service_plan_id            = azurerm_service_plan.asp-knowledge-bot.id
  storage_account_name       = azurerm_storage_account.knowledge-bot-sa.name
  storage_account_access_key = azurerm_storage_account.knowledge-bot-sa.primary_access_key
  https_only                 = true
  identity {
    type = "SystemAssigned"
  }
  

  site_config {
     application_insights_key                      =  azurerm_application_insights.application_insights_kb-blobtrigger.instrumentation_key 
     application_insights_connection_string        =  azurerm_application_insights.application_insights_kb-blobtrigger.connection_string 
     vnet_route_all_enabled                        = true

     application_stack  {
      python_version = "3.10"
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


resource "azurerm_application_insights" "application_insights_kb-blobtrigger" {
  name                        = "ai-${var.project_code}-${lower(var.environment)}-blobtrigger"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  application_type            = "web"
  internet_ingestion_enabled  = "true"
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}

resource "azurerm_application_insights" "kb_backend_ai" {
  name                        = "ai-kb-backend"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  application_type            = "web"
  internet_ingestion_enabled  = "true"
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}

resource "azurerm_search_service" "knowledge_bot_search_service" {
  name                        = "${var.project_code}-${lower(var.environment)}-search"
  location                    = azurerm_resource_group.knowledge-bot.location
  resource_group_name         = azurerm_resource_group.knowledge-bot.name
  sku                         = "basic"

}
