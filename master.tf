resource "libvirt_volume" "master_disk" {
  name             = "${format(local.master_format, count.index + 1)}.${var.volume_format}"
  count            = var.master_nodes
  format           = var.volume_format
  pool             = var.pool_name
  base_volume_name = "${var.coreos_image}.${var.volume_format}"
  size             = var.master_disk_size
}

resource "libvirt_ignition" "master_ignition" {
  name    = "${var.cluster_name}-master-ignition"
  content = file("${path.module}/${var.cluster_name}/master.ign")
}

resource "libvirt_domain" "master" {
  count           = var.master_nodes
  name            = format(local.master_format, count.index + 1)
  vcpu            = var.master_vcpu
  memory          = var.master_memory_size
  coreos_ignition = libvirt_ignition.master_ignition.id
  autostart       = true

  cpu = {
    mode = "host-passthrough"
  }

  disk {
    volume_id = element(libvirt_volume.master_disk.*.id, count.index)
  }

  # Makes the tty0 available via `virsh console`
  console {
    type        = "pty"
    target_port = "0"
  }

  network_interface {
    network_id = libvirt_network.ocp_net.id
    addresses  = [cidrhost(var.network_ip_range, 11 + count.index)]
    hostname   = format("master%d", count.index + 1)

    # When creating the domain resource, wait until the network interface gets
    # a DHCP lease from libvirt, so that the computed IP addresses will be
    # available when the domain is up and the plan applied.
    wait_for_lease = true
  }
}
