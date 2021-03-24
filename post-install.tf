resource "local_file" "registry_pv" {
  content         = templatefile("${path.module}/templates/registry-pv.yaml", { nfs_server = libvirt_domain.storage.network_interface.0.addresses[0] })
  filename        = "${var.cluster_name}/registry-pv.yaml"
  file_permission = "0644"
}

resource "local_file" "nfs_provisioner" {
  content         = templatefile("${path.module}/templates/nfs-provisioner.yaml", { nfs_server = libvirt_domain.storage.network_interface.0.addresses[0] })
  filename        = "${var.cluster_name}/nfs-provisioner.yaml"
  file_permission = "0644"
}

resource "local_file" "ansible_inventory" {
  content         = templatefile("${path.module}/templates/inventory", { nodes = local.all_nodes, network_domain = local.network_domain, dns_server = cidrhost(var.network_ip_range, 1) })
  filename        = "${var.cluster_name}/inventory"
  file_permission = "0644"
}

resource "local_file" "cluster_key" {
  content         = acme_certificate.cluster_cert.private_key_pem
  filename        = "${var.cluster_name}/cluster.key"
  file_permission = "0600"
}

resource "local_file" "cluster_cert" {
  content         = "${acme_certificate.cluster_cert.certificate_pem}${acme_certificate.cluster_cert.issuer_pem}"
  filename        = "${var.cluster_name}/cluster.crt"
  file_permission = "0644"
}
