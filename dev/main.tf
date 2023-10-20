terraform {
  backend "azurerm" {
    resource_group_name  = "azure-chatbot-tfstate"
    storage_account_name = "chatbottfstate"
    container_name       = "tfstate"
    key                  = "knowledge-bot-dev.tfstate"
  }
  required_providers {
    azurerm = {
      version = "3.74.0"
      source  = "hashicorp/azurerm"
    }
  }
}
