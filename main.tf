provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  skip_provider_registration = true
}

terraform {
  backend "azurerm" {
    resource_group_name   = "TerraformBackend"
    storage_account_name  = "terraformbackendstg50"
    container_name        = "terraform-backend"
    key                   = "exchange-lab.tfstate"  # This is the name of the state file to be created in the container.
  }
}

resource "azurerm_resource_group" "exchangelab" {
  name     = "ExchangeLab"
  location = "East US" # Change this based on your preferred region.
}

resource "azurerm_virtual_network" "labnetwork" {
  name                = "LabNetwork"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.exchangelab.location
  resource_group_name = azurerm_resource_group.exchangelab.name
}

resource "azurerm_subnet" "labsubnet" {
  name                 = "LabSubnet"
  resource_group_name  = azurerm_resource_group.exchangelab.name
  virtual_network_name = azurerm_virtual_network.labnetwork.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.exchangelab.location
  resource_group_name = azurerm_resource_group.exchangelab.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "EX01_Web_25"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "25"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "EX01_Web_443"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "EX01_Web_8080"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "WinRM_HTTP"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "WinRM_HTTPS"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5986"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IP for dc01 VM
resource "azurerm_public_ip" "dc01_pip" {
  name                = "dc01-public-ip"
  location            = azurerm_resource_group.exchangelab.location
  resource_group_name = azurerm_resource_group.exchangelab.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "dc01_nic" {
  name                = "dc01-nic"
  location            = azurerm_resource_group.exchangelab.location
  resource_group_name = azurerm_resource_group.exchangelab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.labsubnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.0.4"
    public_ip_address_id          = azurerm_public_ip.dc01_pip.id
  }
}

# Public IP for ex01 VM
resource "azurerm_public_ip" "ex01_pip" {
  name                = "ex01-public-ip"
  location            = azurerm_resource_group.exchangelab.location
  resource_group_name = azurerm_resource_group.exchangelab.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "ex01_nic" {
  name                = "ex01-nic"
  location            = azurerm_resource_group.exchangelab.location
  resource_group_name = azurerm_resource_group.exchangelab.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.labsubnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.0.5"
    public_ip_address_id          = azurerm_public_ip.ex01_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "dc01_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.dc01_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_network_interface_security_group_association" "ex01_nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.ex01_nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_virtual_machine" "dc01" {
  name                  = "DC01"
  location              = azurerm_resource_group.exchangelab.location
  resource_group_name   = azurerm_resource_group.exchangelab.name
  vm_size               = "Standard_DS2_v2"
  network_interface_ids = [azurerm_network_interface.dc01_nic.id]

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "dc01-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "dc01"
    admin_username = var.username
    admin_password = var.password
    custom_data    = file("./files/winrm.ps1")
  }

  os_profile_windows_config {
    provision_vm_agent = true
    winrm {
      protocol = "HTTP"
    }
    # Auto-Login's required to configure WinRM
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.username}</Username></AutoLogon>"
    }

    # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = file("./files/FirstLogonCommands.xml")
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "powershell.exe Install-WindowsFeature -Name AD-Domain-Services",
      "powershell.exe Install-WindowsFeature -Name DNS",
      "powershell.exe Set-ExecutionPolicy Unrestricted -Force"
    ]

    connection {
      type     = "winrm"
      user     = var.username
      password = var.password
      timeout  = "5m"
      https    = false
      insecure = true
      port     = 5985
      host     = azurerm_public_ip.dc01_pip.ip_address
    }
  }
  
  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.dc01_pip.ip_address} >> ansible_inventory.txt"
  }
}
/*
resource "azurerm_virtual_machine" "ex01" {
  name                  = "EX01"
  location              = azurerm_resource_group.exchangelab.location
  resource_group_name   = azurerm_resource_group.exchangelab.name
  vm_size               = "Standard_DS2_v2"
  network_interface_ids = [azurerm_network_interface.ex01_nic.id]

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "ex01-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "ex01"
    admin_username = var.username
    admin_password = var.password
    custom_data    = file("./files/winrm.ps1")
  }

  os_profile_windows_config {
    provision_vm_agent = true
    winrm {
      protocol = "HTTP"
    }
    # Auto-Login's required to configure WinRM
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.username}</Username></AutoLogon>"
    }

    # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
    additional_unattend_config {
      pass         = "oobeSystem"
      component    = "Microsoft-Windows-Shell-Setup"
      setting_name = "FirstLogonCommands"
      content      = file("./files/FirstLogonCommands.xml")
    }
  }
  
    provisioner "remote-exec" {
    inline = [
      "powershell.exe Install-WindowsFeature -Name Web-Server",
      "powershell.exe Set-ExecutionPolicy Unrestricted -Force"
    ]

    connection {
      type     = "winrm"
      user     = var.username
      password = var.password
      timeout  = "5m"
      https    = false
      insecure = true
      port     = 5985
      host     = azurerm_public_ip.ex01_pip.ip_address
    }
  }
  
  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.ex01_pip.ip_address} >> ansible_inventory.txt"
  }
}

output "dc01_public_ip" {
  value = azurerm_public_ip.ex01_pip.ip_address
}

output "ex01_public_ip" {
  value = azurerm_public_ip.dc01_pip.ip_address
}
*/