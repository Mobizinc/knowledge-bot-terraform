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
  }
  tags = {
        environment      = var.environment
        application_name = var.application_name
        Project_Code     = var.project_code
        Owner            = var.owner
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


