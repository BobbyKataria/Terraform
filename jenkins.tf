# create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "uksouth"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    allocation_method            = "Dynamic"
    domain_name_label            = "azureuser1-${formatdate("DDMMYYhhmmss", timestamp())}"
    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "uksouth"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   =  100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "Jenkins"
        priority                   =  200
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }


    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "uksouth"
    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }
    tags = {
        environment = "Terraform Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.myterraformgroup.name}"
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.myterraformgroup.name}"
    location                    = "${azurerm_resource_group.myterraformgroup.location}"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "uksouth"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
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
        computer_name  = "myVM"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = file("/home/adminbk/.ssh/id_rsa.pub")
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.mystorageaccount.primary_blob_endpoint}"
    }

    tags = {
        environment = "Terraform Demo"
    }

    provisioner "local-exec" {
        inline = [
		  "ssh-keygen -t rsa -f /home/adminbk/.ssh/slavekey -q -P ''",
		  "ssh-keygen -t rsa -f /home/adminbk/.ssh/pythonkey -q -P ''",
		  "scp ~/.ssh/slavekey* azureuser@${azurerm_public_ip.myterraformpublicip.fqdn:#filepath}"
                 ]
    }

    provisioner "remote-exec" {
        inline = [ 
                  "git clone https://github.com/BobbyKataria/jenkinTask.git",
                  "cd ~/jenkinTask",
		  "./install.sh",
		  "sudo su jenkins"
                 ]
        connection {
	    type = "ssh"
	    user = "azureuser"
	    private_key = file("/home/adminbk/.ssh/id_rsa")
	    host = "${azurerm_public_ip.myterraformpublicip.fqdn}"
       }
    } 
}
