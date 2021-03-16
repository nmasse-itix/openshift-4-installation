resource "libvirt_network" "ocp_net" {
  name      = var.cluster_name
  mode      = "nat"
  domain    = local.network_domain
  addresses = [var.network_ip_range]
  autostart = true

  dns {
    enabled = true

    hosts {
      hostname = "host"
      ip       = cidrhost(var.network_ip_range, 1)
    }
    hosts {
      hostname = "api"
      ip       = cidrhost(var.network_ip_range, 4)
    }
    hosts {
      hostname = "api-int"
      ip       = cidrhost(var.network_ip_range, 4)
    }
    hosts {
      hostname = "etcd"
      ip       = cidrhost(var.network_ip_range, 4)
    }
  }

  dhcp {
    enabled = true
  }

  xml {
    xslt = templatefile("${path.module}/templates/network.xslt", { alias = "apps.${local.network_domain}", ip = cidrhost(var.network_ip_range, 4) })
  }
}
