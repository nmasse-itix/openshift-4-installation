resource "libvirt_cloudinit_disk" "storage_cloudinit" {
  name           = "${local.storage_name}-cloudinit.iso"
  user_data      = data.template_file.storage_user_data.rendered
  network_config = data.template_file.storage_network_config.rendered
  pool           = libvirt_pool.cluster_storage.name
}

data "template_file" "storage_user_data" {
  template = file("${path.module}/templates/storage/cloud-init.cfg")
}

data "template_file" "storage_network_config" {
  template = file("${path.module}/templates/storage/network-config.cfg")
}

resource "libvirt_volume" "storage_os_disk" {
  name             = "${local.storage_name}-os.${var.volume_format}"
  format           = var.volume_format
  pool             = libvirt_pool.cluster_storage.name
  base_volume_name = "${var.centos_image}.${var.volume_format}"
  base_volume_pool = var.base_image_pool
}

resource "libvirt_volume" "storage_data_disk" {
  name   = "${local.storage_name}-data.${var.volume_format}"
  format = var.volume_format
  pool   = libvirt_pool.cluster_storage.name
  size   = var.storage_disk_size
}

locals {
  storage_node = {
    name = local.storage_name
    ip   = cidrhost(var.network_ip_range, 6)
    mac  = format(var.network_mac_format, 6)
    role = "storage"
  }
}

resource "libvirt_domain" "storage" {
  name       = local.storage_name
  vcpu       = var.storage_vcpu
  memory     = var.storage_memory_size
  cloudinit  = libvirt_cloudinit_disk.storage_cloudinit.id
  autostart  = false
  qemu_agent = true

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.storage_os_disk.id
  }

  disk {
    volume_id = libvirt_volume.storage_data_disk.id
  }

  # Makes the tty0 available via `virsh console`
  console {
    type        = "pty"
    target_port = "0"
  }

  network_interface {
    network_name = var.network_name
    mac          = local.storage_node.mac

    # When creating the domain resource, wait until the network interface gets
    # a DHCP lease from libvirt, so that the computed IP addresses will be
    # available when the domain is up and the plan applied.
    wait_for_lease = true
  }

  xml {
    xslt = file("${path.module}/portgroups/${var.network_portgroup}.xslt")
  }
}
