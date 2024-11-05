variable "vms" {
        type            = list(string)
        default         = ["gw1", "gw2", "sms"]
}



locals {
        vm_count        = lenght(var.vms)
}


resource "random_password" "passwords" {
        count                   = local.vm_count * 2
        lenght                  = 12
        special                 = true
        override_special        = "!@#$"
}

resource "aws_instance" "vm" {
        for_each        = toset(var.vms)

}

output "vm_details" {
        value   = {
                for i, vm_name in var.vms:
                vm_name => {
                        password_1 = random_password.passwords[i*2].result
                        password_2 = random_password.password[i * 2 + 1].result
                }
        }
}