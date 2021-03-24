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

resource "local_file" "dns_config" {
  content         = templatefile("${path.module}/templates/dns.env", { api_server = "api.${local.network_domain}", router = "*.apps.${local.network_domain}", dns_zone = var.base_domain, cluster_name = var.cluster_name })
  filename        = "${var.cluster_name}/dns.env"
  file_permission = "0644"
}

resource "local_file" "ansible_inventory" {
  content         = templatefile("${path.module}/templates/inventory", { nodes = local.all_nodes, network_domain = local.network_domain, dns_server = cidrhost(var.network_ip_range, 1) })
  filename        = "${var.cluster_name}/inventory"
  file_permission = "0644"
}
