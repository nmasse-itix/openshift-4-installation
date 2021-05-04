data "gandi_domain" "public_domain" {
  name = var.base_domain
}

resource "gandi_livedns_record" "api_record" {
  zone = data.gandi_domain.public_domain.id
  name = "api.${var.cluster_name}"
  type = "A"
  ttl  = 300
  values = [
    var.public_cluster_ip
  ]
}

resource "gandi_livedns_record" "router_record" {
  zone = data.gandi_domain.public_domain.id
  name = "*.apps.${var.cluster_name}"
  type = "A"
  ttl  = 300
  values = [
    var.public_cluster_ip
  ]
}