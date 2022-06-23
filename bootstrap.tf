resource "libvirt_volume" "bootstrap_disk" {
  name             = "${local.bootstrap_name}.${var.volume_format}"
  count            = var.bootstrap_nodes
  format           = var.volume_format
  pool             = libvirt_pool.cluster_storage.name
  base_volume_name = "${var.coreos_image}.${var.volume_format}"
  base_volume_pool = var.base_image_pool
  size             = var.bootstrap_disk_size
}

resource "libvirt_ignition" "bootstrap_ignition" {
  name    = "${var.cluster_name}-bootstrap-ignition"
  content = file("${path.module}/.clusters/${var.cluster_name}/bootstrap.ign")
  pool    = libvirt_pool.cluster_storage.name
}

locals {
  bootstrap_nodes = [for i in range(var.bootstrap_nodes) : {
    name = local.bootstrap_name
    ip   = cidrhost(var.network_ip_range, 5)
    mac  = format(var.network_mac_format, 5)
    role = "bootstrap"
  }]
}

resource "libvirt_domain" "bootstrap" {
  name            = local.bootstrap_name
  count           = var.bootstrap_nodes
  vcpu            = var.bootstrap_vcpu
  memory          = var.bootstrap_memory_size
  coreos_ignition = libvirt_ignition.bootstrap_ignition.id
  qemu_agent      = true

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = element(libvirt_volume.bootstrap_disk.*.id, count.index)
  }

  # Makes the tty0 available via `virsh console`
  console {
    type        = "pty"
    target_port = "0"
  }

  network_interface {
    network_name = var.network_name
    mac          = element(local.bootstrap_nodes.*.mac, count.index)

    # When creating the domain resource, wait until the network interface gets
    # a DHCP lease from libvirt, so that the computed IP addresses will be
    # available when the domain is up and the plan applied.
    wait_for_lease = true
  }

  xml {
    xslt = file("${path.module}/portgroups/${var.network_portgroup}.xslt")
  }
}
