provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "AzureLabs" {
  name     = "AzureLabs"
  location = "West Europe"
}


resource "azurerm_virtual_network" "vnetA" {
  name                = "vnetA"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.AzureLabs.location
  resource_group_name = azurerm_resource_group.AzureLabs.name
}


resource "azurerm_virtual_network" "vnetB" {
  name                = "vnetB"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.AzureLabs.location
  resource_group_name = azurerm_resource_group.AzureLabs.name
}


resource "azurerm_virtual_network" "vnetC" {
  name                = "vnetC"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.AzureLabs.location
  resource_group_name = azurerm_resource_group.AzureLabs.name
}


resource "azurerm_virtual_network_peering" "peerAB" {
  name                      = "peerAB"
  resource_group_name       = azurerm_resource_group.AzureLabs.name
  virtual_network_name      = azurerm_virtual_network.vnetA.name
  remote_virtual_network_id = azurerm_virtual_network.vnetB.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}


resource "azurerm_virtual_network_peering" "peerBA" {
  name                      = "peerBA"
  resource_group_name       = azurerm_resource_group.AzureLabs.name
  virtual_network_name      = azurerm_virtual_network.vnetB.name
  remote_virtual_network_id = azurerm_virtual_network.vnetA.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}


resource "azurerm_virtual_network_peering" "peerBC" {
  name                      = "peerBC"
  resource_group_name       = azurerm_resource_group.AzureLabs.name
  virtual_network_name      = azurerm_virtual_network.vnetB.name
  remote_virtual_network_id = azurerm_virtual_network.vnetC.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}


resource "azurerm_virtual_network_peering" "peerCB" {
  name                      = "peerCB"
  resource_group_name       = azurerm_resource_group.AzureLabs.name
  virtual_network_name      = azurerm_virtual_network.vnetC.name
  remote_virtual_network_id = azurerm_virtual_network.vnetB.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
}
