provider "azurerm" {
  features {}
}

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
  default     = "ArchitectApp"
}


#build azure resource group
resource "azurerm_resource_group" "architect_app" {
    name = var.resource_group_name
    location = var.location
    tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}


resource "azurerm_storage_account" "architect-app-sa" {
  name                      = "architectappsa"
  location                    = azurerm_resource_group.architect_app.location
  resource_group_name         = azurerm_resource_group.architect_app.name
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

resource "azurerm_storage_container" "docs" {
  name                  = "docs"
  storage_account_name  = azurerm_storage_account.architect-app-sa.name
  container_access_type = "private"
}

resource "azurerm_storage_queue" "export-request" {
  name                 = "export-request"
  storage_account_name = azurerm_storage_account.architect-app-sa.name
}

resource "azurerm_service_plan" "asp-architect-app" {
  name                = "asp-architect-app"
  location                    = azurerm_resource_group.architect_app.location
  resource_group_name         = azurerm_resource_group.architect_app.name
  os_type             = "Linux"
  sku_name            = "B3"
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}


resource "azurerm_user_assigned_identity" "mi-architect-app" {
 depends_on = [azurerm_key_vault.architect_app_keyvault]
  location                    = azurerm_resource_group.architect_app.location
  resource_group_name         = azurerm_resource_group.architect_app.name
  name                        = "mi-architect-app"
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}

 resource "azurerm_role_assignment" "sa-container" {
   scope                = azurerm_resource_group.architect_app.id
   role_definition_name = "Storage Blob Data Contributor"
   principal_id         = azurerm_user_assigned_identity.mi-architect-app.principal_id
 }

 resource "azurerm_role_assignment" "sa-queue" {
   scope                = azurerm_resource_group.architect_app.id
   role_definition_name = "Storage Queue Data Contributor"
   principal_id         = azurerm_user_assigned_identity.mi-architect-app.principal_id
 }

resource "azurerm_linux_web_app" "architect-app-front-end" {
depends_on = [azurerm_user_assigned_identity.mi-architect-app ] 
  name                        = "architect-app-front-end"
  location                    = azurerm_resource_group.architect_app.location
  resource_group_name         = azurerm_resource_group.architect_app.name
  service_plan_id             = azurerm_service_plan.asp-architect-app.id
  https_only                  = true
  app_settings = {
    WEBSITE_NODE_DEFAULT_VERSION = "18-lts"
    SCM_DO_BUILD_DURING_DEPLOYMENT =  "true"
   }
  identity {
           type         = "SystemAssigned" 
  }
  
  site_config {
     always_on                              = true
     vnet_route_all_enabled                 = false
     application_stack  {
           node_version  = "18-lts"
       
     }  
  }
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
      }
}

resource "azurerm_linux_web_app" "architect-app-back-end" {
depends_on = [azurerm_user_assigned_identity.mi-architect-app ] 
  name                        = "architect-app-back-end"
  location                    = azurerm_resource_group.architect_app.location
  resource_group_name         = azurerm_resource_group.architect_app.name
  service_plan_id             = azurerm_service_plan.asp-architect-app.id
  https_only                  = true
  app_settings = {
    WEBSITE_PYTHON_VERSION = "3.10"
    SCM_DO_BUILD_DURING_DEPLOYMENT =  "true"
    AZURE_CLIENT_ID                = "@Microsoft.KeyVault(VaultName=architect-app-kv;SecretName=AZURE-CLIENT-ID)" 
    DB_NAME                        = "apollo" 
    DB_PSW                         = "@Microsoft.KeyVault(VaultName=architect-app-kv;SecretName=DB-PSW)" 
    DB_SERVER                      = "@Microsoft.KeyVault(VaultName=architect-app-kv;SecretName=DB-SERVER)" 
    DB_USER                        = "@Microsoft.KeyVault(VaultName=architect-app-kv;SecretName=DB-USER)" 
    USER_MANAGED_IDENTITY          = "0" 
    V_AZURE_CLIENT_ID              = "@Microsoft.KeyVault(VaultName=architect-app-kv;SecretName=V-AZURE-CLIENT-ID)" 
    V_AZURE_CLIENT_SECRET          = "@Microsoft.KeyVault(VaultName=architect-app-kv;SecretName=V-AZURE-CLIENT-SECRET)" 
    V_AZURE_TENANT_ID              = "@Microsoft.KeyVault(VaultName=architect-app-kv;SecretName=V-AZURE-TENANT-ID)" 
    REDIS_CACHE_HOST                 = "redis"
    REDIS_CACHE_PASSWORD           = "CX7ixesXYP18Ft50c7tnLgLCPeIrYaxCBAzCaHLSFQg="
    REDIS_CACHE_PORT              = "6379"
    
  }
  identity {
           identity_ids = [azurerm_user_assigned_identity.mi-architect-app.id]
           type         = "UserAssigned" 
        }
  key_vault_reference_identity_id = azurerm_user_assigned_identity.mi-architect-app.id    
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
}

resource "azurerm_service_plan" "asp-architect-logic-app" {
  name                        = "asp-architect-logic-app"
  location                    = azurerm_resource_group.architect_app.location
  resource_group_name         = azurerm_resource_group.architect_app.name
  os_type             = "Windows"
  sku_name            = "WS1"

}

resource "azurerm_logic_app_standard" "architect-app-la" {
  depends_on = [azurerm_service_plan.asp-architect-logic-app]
  name                        = "architect-app-la"
  location                    = azurerm_resource_group.architect_app.location
  resource_group_name         = azurerm_resource_group.architect_app.name
  app_service_plan_id         = azurerm_service_plan.asp-architect-logic-app.id
  storage_account_name        = azurerm_storage_account.architect-app-sa.name
  storage_account_access_key  = azurerm_storage_account.architect-app-sa.primary_access_key

}
