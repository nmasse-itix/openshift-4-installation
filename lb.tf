resource "libvirt_cloudinit_disk" "lb_cloudinit" {
  name           = "${local.lb_name}-cloudinit.iso"
  user_data      = data.template_file.lb_user_data.rendered
  network_config = data.template_file.lb_network_config.rendered
  pool           = var.pool_name
}

data "template_file" "lb_user_data" {
  template = file("${path.module}/templates/lb/cloud-init.cfg")
  vars = {
    haproxy_cfg = templatefile("${path.module}/templates/lb/haproxy.cfg", {
      master_nodes    = { for i in libvirt_domain.master : i.name => i.network_interface.0.addresses[0] },
      worker_nodes    = { for i in libvirt_domain.worker : i.name => i.network_interface.0.addresses[0] },
      bootstrap_nodes = { for i in libvirt_domain.bootstrap : i.name => i.network_interface.0.addresses[0] }
    })
  }
}

data "template_file" "lb_network_config" {
  template = file("${path.module}/templates/lb/network-config.cfg")
  vars = {
    ip  = cidrhost(var.network_ip_range, 4)
    dns = cidrhost(var.network_ip_range, 1)
    gw  = cidrhost(var.network_ip_range, 1)
  }
}

resource "libvirt_volume" "lb_disk" {
  name             = "${local.lb_name}.${var.volume_format}"
  format           = var.volume_format
  pool             = var.pool_name
  base_volume_name = "${var.centos_image}.${var.volume_format}"
  size             = var.lb_disk_size
}

resource "libvirt_domain" "lb" {
  name      = local.lb_name
  vcpu      = var.lb_vcpu
  memory    = var.lb_memory_size
  cloudinit = libvirt_cloudinit_disk.lb_cloudinit.id
  autostart = true

  cpu = {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.lb_disk.id
  }

  # Makes the tty0 available via `virsh console`
  console {
    type        = "pty"
    target_port = "0"
  }

  network_interface {
    network_id     = libvirt_network.ocp_net.id
    addresses      = [cidrhost(var.network_ip_range, 4)]
    hostname       = "lb"
    wait_for_lease = false
  }

  network_interface {
    bridge         = var.external_ifname
    mac            = var.external_mac_address
    wait_for_lease = false
  }
}
