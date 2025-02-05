# 1. Объединение списков
locals  {
    list_A = [1.1.1.132,2.2.2.232]
    list_B = [3.3.3.332, 4.4.4.432]
    concat_list = concat(local.list_A, local.list_B)
}

# 2. Валидация переменных
variable ip_list {
    description = Введите значения списка, например [1.1.1.1,2.2.2.2]n
    type = list(string)

    validation {
    condition = alltrue(
        [
            for ip in var.ip_list  can(
                regex(^(25[0-5]2[0-4][0-9][01][0-9][0-9]).(25[0-5]2[0-4][0-9][01][0-9][0-9]).(25[0-5]2[0-4][0-9][01][0-9][0-9]).(25[0-5]2[0-4][0-9][01][0-9][0-9])$, ip)
            )
            ])
    error_message = Неправильный формат IP-адреса
    }
}

# 3. Манифест

variable ip_list2 {
    description = Введите значения списка, например [1.1.1.132,2.2.2.232]n
    type = list(string)


    

    validation {
        condition = alltrue(
            [
                for ip in var.ip_list2  can(
                    regex(^.{7,15}32$, ip)
                    )])
        error_message = Неправильный формат IP-адреса, маска может быть только 32
    }

    validation {
        condition = alltrue(
            [
                for ip in var.ip_list2  can(
                    regex(^(25[0-5]2[0-4][0-9][01][0-9][0-9]).(25[0-5]2[0-4][0-9][01][0-9][0-9]).(25[0-5]2[0-4][0-9][01][0-9][0-9]).(25[0-5]2[0-4][0-9][01][0-9][0-9])32$, ip)
                    )])
        error_message = Неправильный формат IP-адреса, запись должна быть формата 'x.x.x.x32'
    }

}

locals {
    mega_admin_ip = [8.8.8.832]
    concat_list2 = concat(var.ip_list2, local.mega_admin_ip)
    ip_dict = { for ip in local.concat_list2  ip = ip}
}


output example {
   value = local.ip_dict
}

resource aws_security_group sg {
    ingress {
        from_port = 0
        to_port = 0
        protocol = -1 
        cidr_blocks = local.concat_list2
    }

    egress {
        from_port = 25
        to_port = 25
        protocol = tcp
        cidr_blocks = local.concat_list2
    }

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1 
    cidr_blocks = [0.0.0.00]
    }
  
}