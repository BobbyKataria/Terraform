#install file for terraform v 0.12.3

sudo apt get upgrade

sudo apt upgrade -y

sudo apt install -y unzip wget

wget https://releases.hashicorp.com/terraform/0.12.3/terraform_0.12.3_linux_amd64.zip

unzip terraform_*_linux_*.zip

sudo mv terraform /usr/local/bin

rm terraform_*_linux_*.zip

terraform --version
