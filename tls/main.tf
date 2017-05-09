module "ca" {
  source            = "ca"
  organization      = "auto"
  common_name       = "uat.auto.ubisoft.onbe"
  dns_names_list    = "uat.auto.ubisoft.onbe"
  is_ca_certificate = true
}

module "docker_daemon_certs" {
  source                = "docker/daemon"
  ca_cert_pem           = "${module.ca.ca_cert_pem}"
  ca_private_key_pem    = "${module.ca.ca_private_key_pem}"
  validity_period_hours = 43800
  early_renewal_hours   = 720
  dns_names_list        = "uat.auto.ubisoft.onbe"
}

module "docker_client_certs" {
  source                = "docker/client"
  ca_cert_pem           = "${module.ca.ca_cert_pem}"
  ca_private_key_pem    = "${module.ca.ca_private_key_pem}"
  validity_period_hours = 43800
  early_renewal_hours   = 720
  dns_names_list        = "uat.auto.ubisoft.onbe"
}
