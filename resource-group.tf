#Creating our resource group

resource "azurerm_resource_group" "myterraformgroup" {
	name		= "mResourceGroup"
	location	= "uksouth"

	tags = {
		environment = "Terraform Demo"
	}
}
