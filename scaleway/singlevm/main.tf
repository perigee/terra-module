variable "vm_name" {
  default = "testing"
}

variable "vm_tags" {
  type    = "list"
  default = ["testing"]
}

variable "vm_sg" {
  default = "500caed3-3d35-42cc-930b-11447ee64bde"
}

resource "scaleway_server" "single" {
  name                = "${var.vm_name == "testing" ? format("%s_%s", var.vm_name, timestamp()) : var.vm_name}"
  image               = "89ee4018-f8c3-4dc4-a6b5-bca14f985ebe"
  type                = "VC1S"
  tags                = "${var.vm_tags}"
  security_group      = "${var.vm_sg}"
  dynamic_ip_required = true
}

output "ipv4" {
  value = "${scaleway_server.single.public_ip}"
}
