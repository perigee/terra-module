variable "ca_cert_pem" {}
variable "ca_private_key_pem" {}

variable "dns_names_list" {}

variable "rsa_bits" {
  default = 2048
}

variable "validity_period_hours" {}
variable "early_renewal_hours" {}

variable "deploy_hosts" {
  type = "list"
}

variable "deploy_hosts_count" {}

variable "ssh_user" {
  default = "autoadmin"
}

variable "ssh_private_key" {}

# docker_client certs
resource "tls_private_key" "docker_client" {
  algorithm = "RSA"
  rsa_bits  = "${var.rsa_bits}"
}

resource "tls_cert_request" "docker_client" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.docker_client.private_key_pem}"

  subject {
    common_name = "docker-client"
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
    "key_encipherment",
  ]
}

resource "null_resource" "configure-docker-client-certs" {
  count = "${var.deploy_hosts_count}"

  triggers {
    docker_client_count       = "${length(var.deploy_hosts)}"
    docker_client_private_key = "${tls_private_key.docker_client.private_key_pem}"
    docker_client_certs_pem   = "${element(tls_locally_signed_cert.docker_client.*.cert_pem, count.index)}"
    validity_period_hours     = "${var.validity_period_hours}"
    early_renewal_hours       = "${var.early_renewal_hours}"
    dns_names_list            = "${var.dns_names_list}"
  }

  connection {
    user        = "${var.ssh_user}"
    private_key = "${var.ssh_private_key}"
    host        = "${element(var.deploy_hosts, count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "if [ ! -d '/home/${var.ssh_user}/.docker' ]; then sudo mkdir -p /home/${var.ssh_user}/.docker;fi",
      "echo '${var.ca_cert_pem}' | sudo tee /home/${var.ssh_user}/.docker/ca.pem",
      "echo '${tls_private_key.docker_client.private_key_pem}' | sudo tee /home/${var.ssh_user}/.docker/key.pem",
      "echo '${tls_locally_signed_cert.docker_client.cert_pem}' | sudo tee /home/${var.ssh_user}/.docker/cert.pem",
      "sudo chmod 644 /home/${var.ssh_user}/.docker/ca.pem",
      "sudo chmod 600 /home/${var.ssh_user}/.docker/key.pem",
      "sudo chmod 644 /home/${var.ssh_user}/.docker/cert.pem",
      "sudo chown ${var.ssh_user}:${var.ssh_user} /home/${var.ssh_user}/.docker/*",
    ]
  }
}

output "private_key" {
  value = "${tls_private_key.docker_client.private_key_pem}"
}

output "cert_pems" {
  value = "${tls_locally_signed_cert.docker_client.cert_pem}"
}
