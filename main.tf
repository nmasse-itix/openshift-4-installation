terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">=0.6.3"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.0.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">=2.2.0"
    }
    ignition = {
      source  = "community-terraform-providers/ignition"
      version = "2.1.2"
    }
    gandi = {
      version = "2.0.0"
      source  = "github/go-gandi/gandi"
    }
  }
}

locals {
  ocp_nodes        = { for i in concat(libvirt_domain.bootstrap, libvirt_domain.master, libvirt_domain.worker) : i.name => i.network_interface.0.addresses[0] }
  additional_nodes = { (libvirt_domain.lb.name) = cidrhost(var.network_ip_range, 4), (libvirt_domain.storage.name) = libvirt_domain.storage.network_interface.0.addresses[0] }
  all_nodes        = merge(local.ocp_nodes, local.additional_nodes)
}

output "machines" {
  value = local.all_nodes
}
