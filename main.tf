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
    resource_group_name  = "TerraformBackend"
    storage_account_name = "terraformbackendstg51"
    container_name       = "terraform-backend"
    key                  = "exchange-lab.tfstate"
  }
}

resource "azurerm_resource_group" "exchangelab" {
  name     = "ExchangeLab"
  location = "East US"
}

resource "azurerm_virtual_network" "labnetwork" {
  name                = "LabNetwork"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.exchangelab.location
  resource_group_name = azurerm_resource_group.exchangelab.name
  dns_servers         = var.custom_dns != "" ? [var.custom_dns] : []
}

resource "azurerm_subnet" "labsubnet" {
  name                 = "LabSubnet"
  resource_group_name  = azurerm_resource_group.exchangelab.name
  virtual_network_name = azurerm_virtual_network.labnetwork.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "LabNSG"
  location            = azurerm_resource_group.exchangelab.location
  resource_group_name = azurerm_resource_group.exchangelab.name

  security_rule {
    name                       = "AllowAllInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
/*
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
*/

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
      # Install necessary Windows features
      "powershell.exe Install-WindowsFeature -Name DNS",
      "powershell.exe Install-WindowsFeature -Name AD-Domain-Services",
      "powershell.exe Install-WindowsFeature RSAT-ADDS",
      "powershell.exe Install-WindowsFeature RSAT-ADLDS",
      "powershell.exe $domainName = '${var.dc_domain_name}'; $safeModeAdminPassword = ConvertTo-SecureString '${var.password}' -AsPlainText -Force; Install-ADDSForest -DomainName $domainName -SafeModeAdministratorPassword $safeModeAdminPassword -Force -Confirm:$false",
    ]

    connection {
      type     = "winrm"
      user     = var.username
      password = var.password
      timeout  = "10m"
      https    = false
      insecure = true
      port     = 5985
      host     = azurerm_public_ip.dc01_pip.ip_address
    }
  }

  provisioner "local-exec" {
    command = "sleep 600" # Wait for 10 minutes
  }

  provisioner "remote-exec" {
    inline = [
      "powershell.exe Set-ExecutionPolicy Unrestricted -Force",
      "powershell.exe Import-Module ActiveDirectory",
      "powershell.exe -Command \"Rename-ADObject -Identity 'CN=Default-First-Site-Name,CN=Sites,CN=Configuration,DC=demolabs50,DC=local' -NewName 'Azure'\"",
      "powershell.exe New-ADReplicationSubnet -Name '10.1.0.0/24' -Description 'LabSubnet' -Site 'Azure'",
    ]

    connection {
      type     = "winrm"
      user     = var.username
      password = var.password
      timeout  = "10m"
      https    = false
      insecure = true
      port     = 5985
      host     = azurerm_public_ip.dc01_pip.ip_address
    }
  }

  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.dc01_pip.ip_address} > ansible_inventory.txt"
  }
}

resource "azurerm_virtual_machine" "ex01" {
  count                 = var.create_exchange ? 1 : 0
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


  provisioner "file" {
    source      = "./files/exchange_config.ps1"
    destination = "C:\\Temp\\exchange_config.ps1"

      connection {
      type     = "winrm"
      user     = var.username
      password = var.password
      timeout  = "15m"
      https    = false
      insecure = true
      port     = 5985
      host     = azurerm_public_ip.ex01_pip.ip_address
    }
  }
  
  /*
  provisioner "remote-exec" {
    inline = [
      "powershell.exe -File C:\\Temp\\exchange_config.ps1"
    ]

    connection {
      type     = "winrm"
      user     = var.username
      password = var.password
      timeout  = "15m"
      https    = false
      insecure = true
      port     = 5985
      host     = azurerm_public_ip.ex01_pip.ip_address
    }
  }
  */
  
  provisioner "local-exec" {
    command = "sleep 300" # Wait for 5 minutes
  }

  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.ex01_pip.ip_address} >> ansible_inventory.txt"
  }
}

output "dc01_public_ip" {
  value = azurerm_public_ip.dc01_pip.ip_address
}

output "ex01_public_ip" {
  value = azurerm_public_ip.ex01_pip.ip_address
}
