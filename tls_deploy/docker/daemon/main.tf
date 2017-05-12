variable "rsa_bits" {
  default = 2048
}

variable "ca_cert_pem" {}
variable "ca_private_key_pem" {}

variable "ip_addresses_list" {
  default = []
}

variable "dns_names_list" {
  default = ""
}

variable "default_ip_list" {
  default = []
}

variable "ip_list" {
  default = []
}

variable "validity_period_hours" {
  default = 8760
}

variable "early_renewal_hours" {
  default = 720
}

variable "ssh_user" {
  default = "autoadmin"
}

variable "ssh_private_key" {}

# docker_daemon certs
resource "tls_private_key" "docker_daemon" {
  algorithm = "RSA"
  rsa_bits  = "${var.rsa_bits}"
}

variable "deploy_hosts" {
  type = "list"
}

variable "deploy_hosts_count" {}

variable "deploy_path" {
  default = "/etc/docker/certs"
}

resource "tls_cert_request" "docker_daemon" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.docker_daemon.private_key_pem}"

  subject {
    common_name = "docker_daemon"
  }

  dns_names    = ["${split(",", var.dns_names_list)}"]
  ip_addresses = ["${concat(var.default_ip_list, var.ip_list)}"]
}

resource "tls_locally_signed_cert" "docker_daemon" {
  cert_request_pem   = "${tls_cert_request.docker_daemon.cert_request_pem}"
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

###########################
# Deploy on target machine
###########################

resource "null_resource" "configure-docker-dameon-certs" {
  count = "${var.deploy_hosts_count}"

  triggers {
    docker_daemon_count       = "${length(var.deploy_hosts)}"
    docker_daemon_private_key = "${tls_private_key.docker_daemon.private_key_pem}"
    docker_daemon_certs_pem   = "${element(tls_locally_signed_cert.docker_daemon.*.cert_pem, count.index)}"
    validity_period_hours     = "${var.validity_period_hours}"
    early_renewal_hours       = "${var.early_renewal_hours}"
    ip_addresses_list         = "${join(",", var.ip_list)}"
    dns_names_list            = "${var.dns_names_list}"
  }

  connection {
    user        = "${var.ssh_user}"
    private_key = "${var.ssh_private_key}"
    host        = "${element(var.deploy_hosts, count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "if [ ! -d ${var.deploy_path} ]; then sudo mkdir -p ${var.deploy_path};fi",
      "echo '${var.ca_cert_pem}' | sudo tee ${var.deploy_path}/ca.pem",
      "echo '${tls_private_key.docker_daemon.private_key_pem}' | sudo tee ${var.deploy_path}/server-key.pem",
      "echo '${tls_locally_signed_cert.docker_daemon.cert_pem}' | sudo tee ${var.deploy_path}/server-cert.pem",
      "sudo chmod 644 ${var.deploy_path}/ca.pem",
      "sudo chmod 600 ${var.deploy_path}/server-key.pem",
      "sudo chmod 644 ${var.deploy_path}/server-cert.pem",
    ]
  }
}

output "private_key" {
  value = "${tls_private_key.docker_daemon.private_key_pem}"
}

output "cert_pems" {
  value = "${tls_locally_signed_cert.docker_daemon.cert_pem}"
}
