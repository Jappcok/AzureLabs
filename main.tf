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

resource "azurerm_subnet" "subA" {
  name                 = "subnetA"
  resource_group_name  = azurerm_resource_group.AzureLabs.name
  virtual_network_name = azurerm_virtual_network.vnetA.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "subB" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.AzureLabs.name
  virtual_network_name = azurerm_virtual_network.vnetB.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_subnet" "subC" {
  name                 = "subnetC"
  resource_group_name  = azurerm_resource_group.AzureLabs.name
  virtual_network_name = azurerm_virtual_network.vnetC.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource "azurerm_public_ip" "publicip1" {
  name                = "ip1"
  location            = azurerm_resource_group.AzureLabs.location
  resource_group_name = azurerm_resource_group.AzureLabs.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "firewall" {
  name                = "firewall"
  location            = azurerm_resource_group.AzureLabs.location
  resource_group_name = azurerm_resource_group.AzureLabs.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.subB.id
    public_ip_address_id = azurerm_public_ip.publicip1.id
  }
}

resource "azurerm_firewall_network_rule_collection" "rule1" {
  name                = "AtoC"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.AzureLabs.name
  priority            = 110
  action              = "Allow"

  rule {
    name = "Allow-AtoC"
    source_addresses = ["10.0.0.0/24"]
    destination_addresses = ["10.2.0.0/24"]
    destination_ports = [ "1-65535" ]
    protocols = [ "TCP" ]
  }
}

resource "azurerm_route_table" "routetableA" {
  name                          = "RouteTableA"
  location                      = azurerm_resource_group.AzureLabs.location
  resource_group_name           = azurerm_resource_group.AzureLabs.name
  disable_bgp_route_propagation = false

  route {
    name           = "To-C"
    address_prefix = "10.2.0.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "sub1rt" {
  subnet_id      = azurerm_subnet.subA.id
  route_table_id = azurerm_route_table.routetableA.id
}

resource "azurerm_route_table" "routetableC" {
  name                          = "RouteTableC"
  location                      = azurerm_resource_group.AzureLabs.location
  resource_group_name           = azurerm_resource_group.AzureLabs.name
  disable_bgp_route_propagation = false

  route {
    name           = "To-A"
    address_prefix = "10.0.0.0/20"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "sub2rt" {
  subnet_id      = azurerm_subnet.subC.id
  route_table_id = azurerm_route_table.routetableC.id
}

resource "azurerm_network_interface" "nicA" {
  name                = "NICA"
  location            = azurerm_resource_group.AzureLabs.location
  resource_group_name = azurerm_resource_group.AzureLabs.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subA.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vmA" {
  name                = "vmA"
  resource_group_name = azurerm_resource_group.AzureLabs.name
  location            = azurerm_resource_group.AzureLabs.location
  size                = "Standard_F2"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.nicA.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "nicC" {
  name                = "NICC"
  location            = azurerm_resource_group.AzureLabs.location
  resource_group_name = azurerm_resource_group.AzureLabs.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subC.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vmC" {
  name                = "vmC"
  resource_group_name = azurerm_resource_group.AzureLabs.name
  location            = azurerm_resource_group.AzureLabs.location
  size                = "Standard_F2"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.nicC.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}