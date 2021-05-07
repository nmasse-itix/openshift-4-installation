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
      master_nodes    = { for i in local.master_nodes : i.name => i.ip },
      worker_nodes    = { for i in local.worker_nodes : i.name => i.ip },
      bootstrap_nodes = { for i in local.bootstrap_nodes : i.name => i.ip }
    })
  }
}

data "template_file" "lb_network_config" {
  template = file("${path.module}/templates/lb/network-config.cfg")
}

resource "libvirt_volume" "lb_disk" {
  name             = "${local.lb_name}.${var.volume_format}"
  format           = var.volume_format
  pool             = var.pool_name
  base_volume_name = "${var.centos_image}.${var.volume_format}"
  size             = var.lb_disk_size
}

locals {
  lb_node = {
    name = local.lb_name
    ip   = cidrhost(var.network_ip_range, 4)
    mac  = format(var.network_mac_format, 4)
    role = "lb"
  }
}

resource "libvirt_domain" "lb" {
  name       = local.lb_name
  vcpu       = var.lb_vcpu
  memory     = var.lb_memory_size
  cloudinit  = libvirt_cloudinit_disk.lb_cloudinit.id
  autostart  = false
  qemu_agent = true

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
    network_name = var.network_name
    mac          = local.lb_node.mac

    # When creating the domain resource, wait until the network interface gets
    # a DHCP lease from libvirt, so that the computed IP addresses will be
    # available when the domain is up and the plan applied.
    wait_for_lease = true
  }

  xml {
    xslt = file("${path.module}/portgroups/${var.network_portgroup}.xslt")
  }
}
