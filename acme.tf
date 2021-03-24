resource "tls_private_key" "account_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "acme_registration" "cluster_reg" {
  account_key_pem = tls_private_key.account_key.private_key_pem
  email_address   = var.acme_account_email
}

resource "acme_certificate" "cluster_cert" {
  account_key_pem           = acme_registration.cluster_reg.account_key_pem
  common_name               = "api.${local.network_domain}"
  subject_alternative_names = ["*.apps.${local.network_domain}"]
  key_type                  = "2048" // RSA 2048

  dns_challenge {
    provider = "gandiv5"
  }
}
