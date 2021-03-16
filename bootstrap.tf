resource "libvirt_volume" "bootstrap_disk" {
  name             = "${local.bootstrap_name}.${var.volume_format}"
  count            = var.bootstrap_nodes
  format           = var.volume_format
  pool             = var.pool_name
  base_volume_name = "${var.coreos_image}.${var.volume_format}"
  size             = var.bootstrap_disk_size
}

resource "libvirt_ignition" "bootstrap_ignition" {
  name    = "${var.cluster_name}-bootstrap-ignition"
  content = file("${path.module}/${var.cluster_name}/bootstrap.ign")
}

resource "libvirt_domain" "bootstrap" {
  name            = local.bootstrap_name
  count           = var.bootstrap_nodes
  vcpu            = var.bootstrap_vcpu
  memory          = var.bootstrap_memory_size
  coreos_ignition = libvirt_ignition.bootstrap_ignition.id

  disk {
    volume_id = element(libvirt_volume.bootstrap_disk.*.id, count.index)
  }

  # Makes the tty0 available via `virsh console`
  console {
    type        = "pty"
    target_port = "0"
  }

  network_interface {
    network_id = libvirt_network.ocp_net.id
    addresses  = [cidrhost(var.network_ip_range, 5)]
    hostname   = "bootstrap"

    # When creating the domain resource, wait until the network interface gets
    # a DHCP lease from libvirt, so that the computed IP addresses will be
    # available when the domain is up and the plan applied.
    wait_for_lease = true
  }
}
