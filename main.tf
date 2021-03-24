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
    acme = {
      source  = "vancluever/acme"
      version = "2.3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">=3.1.0"
    }
  }
}

locals {
  master_nodes     = [for i in libvirt_domain.master : { name = i.name, ip = i.network_interface.0.addresses[0], role = "master" }]
  worker_nodes     = [for i in libvirt_domain.worker : { name = i.name, ip = i.network_interface.0.addresses[0], role = "worker" }]
  bootstrap_nodes  = [for i in libvirt_domain.bootstrap : { name = i.name, ip = i.network_interface.0.addresses[0], role = "bootstrap" }]
  additional_nodes = [{ name = (libvirt_domain.lb.name), ip = [libvirt_domain.lb.network_interface.0.addresses[0], libvirt_domain.lb.network_interface.1.addresses[0]], role = "lb" }, { name = (libvirt_domain.storage.name), ip = libvirt_domain.storage.network_interface.0.addresses[0], role = "storage" }]
  all_nodes        = concat(local.additional_nodes, local.master_nodes, local.worker_nodes, local.bootstrap_nodes)
}

output "machines" {
  value = local.all_nodes
}
