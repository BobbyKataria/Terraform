# create public IPs
resource "azurerm_public_ip" "myterraformpublicip2" {
    name                         = "myPublicIP2"
    location                     = "uksouth"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    allocation_method            = "Dynamic"
    domain_name_label            = "azureuser2-${formatdate("DDMMYYhhmmss", timestamp())}"
    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg2" {
    name                = "myNetworkSecurityGroup2"
    location            = "uksouth"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 300
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic2" {
    name                      = "myNIC2"
    location                  = "uksouth"
    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg2.id}"

    ip_configuration {
        name                          = "myNicConfiguration2"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip2.id}"
    }
    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm2" {
    name                  = "myVM2"
    location              = "uksouth"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic2.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk2"
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
        computer_name  = "myVM2"
        admin_username = "azureuser2"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
          path     = "/home/azureuser2/.ssh/authorized_keys"
          key_data = file("/home/adminbk/.ssh/id_rsa.pub")
        }
    }

    tags = {
        environment = "Terraform Demo"
    }

    provisioner "local-exec" {
        inline = [
                  "",
                  "",
                  "sudo su jenkins",
                 ]
        connection {
            type = "ssh"
            user = "azureuser2"
            private_key = file("/home/adminbk/.ssh/id_rsa")
            host = "${azurerm_public_ip.myterraformpublicip2.fqdn}"

    provisioner "remote-exec" {
        inline = [
                  "sudo user add --create-home jenkins",
		  "sudo usermod --create-home",
                  "sudo su jenkins",
		  
                 ]
        connection {
            type = "ssh"
            user = "azureuser2"
            private_key = file("/home/adminbk/.ssh/id_rsa")
            host = "${azurerm_public_ip.myterraformpublicip2.fqdn}"
       }
    }
}

