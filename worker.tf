resource "libvirt_volume" "worker_disk" {
  name             = "${format(local.worker_format, count.index + 1)}.${var.volume_format}"
  count            = var.worker_nodes
  format           = var.volume_format
  pool             = var.pool_name
  base_volume_name = "${var.coreos_image}.${var.volume_format}"
  size             = var.worker_disk_size
}

resource "libvirt_ignition" "worker_ignition" {
  name    = "${var.cluster_name}-worker-ignition"
  content = file("${path.module}/${var.cluster_name}/worker.ign")
}

resource "libvirt_domain" "worker" {
  count           = var.worker_nodes
  name            = format(local.worker_format, count.index + 1)
  vcpu            = var.worker_vcpu
  memory          = var.worker_memory_size
  coreos_ignition = libvirt_ignition.worker_ignition.id
  autostart       = false

  cpu = {
    mode = "host-passthrough"
  }

  disk {
    volume_id = element(libvirt_volume.worker_disk.*.id, count.index)
  }

  # Makes the tty0 available via `virsh console`
  console {
    type        = "pty"
    target_port = "0"
  }

  network_interface {
    network_id = libvirt_network.ocp_net.id
    addresses  = [cidrhost(var.network_ip_range, 21 + count.index)]
    hostname   = format("worker%d", count.index + 1)

    # When creating the domain resource, wait until the network interface gets
    # a DHCP lease from libvirt, so that the computed IP addresses will be
    # available when the domain is up and the plan applied.
    wait_for_lease = true
  }
}
