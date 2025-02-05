locals {
    EC2_ACCESS_KEY = "${var.admin.C2_PROJECT}:${var.admin.BASE_ACCESS_KEY}"
    username = split("@", var.admin.BASE_ACCESS_KEY)[0]
}
# Define the SSH key pair for each VM
resource "tls_private_key" "ssh_key_pair" {
  count = var.vms_count
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Configue cloud-init config from template
data "template_file" "init" {
  count = var.vms_count
  template = "${file("cloudconfig.tftpl")}"
  vars = {
    username = local.username
    ansible_ssh_key = tls_private_key.ssh_key_pair[count.index].public_key_openssh
    admin_ssh_key = var.admin.Administrator_SSH_Pub_key
  }
}

variable "vms" {
  type    = list(string)
  default = ["gw1", "gw2", "sms"]
}

locals {
  vm_count = length(var.vms)
}


resource "random_password" "passwords" {
  count             = local.vm_count * 2
  length            = 12
  special           = true
  override_special  = "!@#$"
}


resource "aws_instance" "vm" {
  for_each = toset(var.vms)

  ami           = var.vm_template
  instance_type = var.vm_instance_type
  subnet_id     = var.vm_subnet
  vpc_security_group_ids = [var.vm_securitygroup]

  associate_public_ip_address = true

  tags = {
    Name = each.key
  }

  ebs_block_device {
    delete_on_termination = true
    device_name           = "disk1"
    volume_type           = var.vm_volume_type
    volume_size           = var.vm_volume_size

    tags = {
      Name = "Disk for ${each.key}"
    }
  }
}


output "vm_details" {
value = {
    for i, vm_name in var.vms :
    vm_name => {
      password_1 = random_password.passwords[i * 2].result
      password_2 = random_password.passwords[i * 2 + 1].result
    }
  }
sensitive = true
}


terraform {
  required_providers {
    aws = {
      source  = "hc-registry.website.k2.cloud/c2devel/rockitcloud"
      version = "24.1.0"
    }
  }
}

provider "aws" {
  endpoints {
    ec2 = "https://ec2.k2.cloud"
  }

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  insecure   = false
  access_key = local.EC2_ACCESS_KEY
  secret_key = var.admin.EC2_SECRET_KEY
  region     = "region-1"
}


provider "aws" {
  alias = "noregion"
  endpoints {
    s3 = "https://s3.k2.cloud"
  }

  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_region_validation      = true

  insecure   = false
  access_key = local.EC2_ACCESS_KEY
  secret_key = var.admin.EC2_SECRET_KEY
  region     = "us-east-1"
}

# Переменные для конфигурации
variable "admin" {
  type = object(
    {
      C2_PROJECT            = string
      BASE_ACCESS_KEY       = string
      EC2_SECRET_KEY        = string
      Administrator_SSH_Pub_key = string
    })
  default = {
    C2_PROJECT            = ""
    BASE_ACCESS_KEY       = ""
    EC2_SECRET_KEY        = ""
    Administrator_SSH_Pub_key = ""
	}
}

variable "az" {
  default = "ru-msk-comp1p"
}

variable "vms_count" {
  default = 0
}

variable "vm_name_prefix" {
  default = "example_vm"
}

variable "vm_template" {
  default = "cmi-D01767A6"
}

variable "vm_instance_type" {
  default = "m5.2small"
}

variable "vm_volume_type" {
  default = "gp2"
}

variable "vm_volume_size" {
  description = "Enter the volume size for VM disks (32 by default, in GiB, must be multiple of 32)"
  default     = 32
}

variable "vm_subnet" {
  default = "subnet-AA6E4202"
}

variable "vm_securitygroup" {
  default = "sg-B80EB9BF"
}