# Configure the Microsoft Azure Provider
#provider "azurerm" {
#    subscription_id = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#    client_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#    client_secret   = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#    tenant_id       = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
#}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "olidbtestgroup" {
    name     = "OliDBTestResourceGroup"
    location = "eastus"

    tags {
        environment = "Oli DB Test"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "olidbtestnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.olidbtestgroup.name}"

    tags {
        environment = "Oli DB Test"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.olidbtestgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.olidbtestnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.olidbtestgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Oli DB Test"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "olidbtestsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.olidbtestgroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "Oli DB Test"
    }
}

# Create network interface
resource "azurerm_network_interface" "olidbtestnic" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.olidbtestgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.olidbtestsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags {
        environment = "Oli DB Test"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.olidbtestgroup.name}"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.olidbtestgroup.name}"
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags {
        environment = "Oli DB Test"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.olidbtestgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.olidbtestnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAwGfJEmmCbMau7p7BzQ+/l2Fdc90PCBV2Hro19xUdpHFM/e5xL5EJ/sADTJ+2dXETvLL7bmJG80uo2/k+pdx/Se7t0H6CkrVWRip4Wmz/gNQQlqpl5zWSVmCMLOAd3wZ9h9MvJiCarzNMb4B2ewrFQeO3LsiGZzH17B1V0NrvI7l5fVUnYBO5AEyNrQsHr5Xqx4Z5q3g9fEhaC0i1BBYbmdtXtBL+nSvXUHsizgkGzWeMUKCeelUeMk9v/rC26C1s5+2AhofiTEfUUQfBF7UggXnmiC+U5u/cFBoL/HODZwzTLrR+xqKriVTgsY7jQ8anMxY+1ylZ3HuP7QAsgqKpCQ=="
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags {
        environment = "Oli DB Test"
    }
}

