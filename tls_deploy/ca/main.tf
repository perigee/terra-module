variable "rsa_bits" {
  default = 2048
}

variable "organization" {
  default = "auto"
}

variable "validity_period_hours" {
  default = 24000
}

variable "early_renewal_hours" {
  default = 720
}

variable "is_ca_certificate" {
  default = true
}

variable "common_name" {}

variable "dns_names_list" {
  default = ""
}

variable "default_ip_list" {
  default = []
}

variable "ip_list" {
  default = []
}

variable "ssh_user" {
  default = "autoadmin"
}

resource "tls_private_key" "ca" {
  algorithm = "RSA"
  rsa_bits  = "${var.rsa_bits}"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.ca.private_key_pem}"

  subject {
    common_name  = "${var.common_name}"
    organization = "${var.organization}"
  }

  dns_names    = ["${split(",", var.dns_names_list)}"]
  ip_addresses = ["${concat(var.default_ip_list, var.ip_list)}"]

  allowed_uses = [
    "key_encipherment",
    "cert_signing",
    "server_auth",
    "client_auth",
  ]

  validity_period_hours = "${var.validity_period_hours}"
  early_renewal_hours   = "${var.early_renewal_hours}"
  is_ca_certificate     = "${var.is_ca_certificate}"
}

output "ca_cert_pem" {
  value = "${tls_self_signed_cert.ca.cert_pem}"
}

output "ca_private_key_pem" {
  value = "${tls_private_key.ca.private_key_pem}"
}
