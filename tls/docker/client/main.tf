variable "ca_cert_pem" {}
variable "ca_private_key_pem" {}
variable "ip_addresses_list" { default = [] }
# supports if you have a public/private ip and you want to set the private ip
# for internal cert but use the public_ip to connect via ssh

variable "dns_names_list" {}
variable "common_name" {}

variable "validity_period_hours" {}
variable "early_renewal_hours" {}


# docker_client certs
resource "tls_private_key" "docker_client" {
  algorithm = "RSA"
}

resource "tls_cert_request" "docker_client" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.docker_client.private_key_pem}"

  subject {
    common_name  = "${var.common_name}"
  }

  dns_names = ["${split(",", var.dns_names_list)}"]
}

resource "tls_locally_signed_cert" "docker_client" {
  cert_request_pem   = "${tls_cert_request.docker_client.cert_request_pem}"
  ca_key_algorithm   = "RSA"
  ca_private_key_pem = "${var.ca_private_key_pem}"
  ca_cert_pem        = "${var.ca_cert_pem}"

  validity_period_hours = "${var.validity_period_hours}"
  early_renewal_hours   = "${var.early_renewal_hours}"

  allowed_uses = [
    "server_auth",
    "client_auth",
    "digital_signature",
    "key_encipherment"
  ]
}

output "private_key" {
  value = "${tls_private_key.docker_client.private_key_pem}"
}

output "cert_pems" {
  value = "${tls_locally_signed_cert.docker_client.cert_pem}"
}
