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

locals {
  worker_nodes = [for i in range(var.worker_nodes) : {
    name = format(local.worker_format, i + 1)
    ip   = cidrhost(var.network_ip_range, 21 + i)
    mac  = format(var.network_mac_format, 21 + i)
    role = "worker"
  }]
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
    network_name   = var.network_name
    mac            = element(local.worker_nodes.*.mac, count.index)
    wait_for_lease = false
  }

  xml {
    xslt = file("${path.module}/portgroups/${var.network_portgroup}.xslt")
  }
}
