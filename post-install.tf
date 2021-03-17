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

resource "local_file" "stop_sh" {
  content         = templatefile("${path.module}/templates/stop.sh", { masters = libvirt_domain.master.*.name, workers = libvirt_domain.worker.*.name, lb = libvirt_domain.lb.name, storage = libvirt_domain.storage.name })
  filename        = "${var.cluster_name}/stop.sh"
  file_permission = "0755"
}

resource "local_file" "start_sh" {
  content         = templatefile("${path.module}/templates/start.sh", { masters = local.master_nodes, workers = local.worker_nodes, others = local.additional_nodes })
  filename        = "${var.cluster_name}/start.sh"
  file_permission = "0755"
}

resource "null_resource" "dnsmasq_config" {
  triggers = {
    network_id = libvirt_network.ocp_net.id
    libvirt_server = local.libvirt_server
    libvirt_username = local.libvirt_username
    network_domain = local.network_domain
  }

  connection {
    type = "ssh"
    host = self.triggers.libvirt_server
    user = self.triggers.libvirt_username
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'server=/${local.network_domain}/${cidrhost(var.network_ip_range, 1)}' | sudo tee /etc/NetworkManager/dnsmasq.d/zone-${local.network_domain}.conf",
      "sudo pkill -f '[d]nsmasq.*--enable-dbus=org.freedesktop.NetworkManager.dnsmasq'"
    ]
  }

  provisioner "remote-exec" {
    when = destroy
    on_failure = continue
    inline = [
      "sudo rm -f /etc/NetworkManager/dnsmasq.d/zone-${self.triggers.network_domain}.conf",
      "sudo pkill -f '[d]nsmasq.*--enable-dbus=org.freedesktop.NetworkManager.dnsmasq'"
    ]
  }
}
