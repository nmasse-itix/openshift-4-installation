terraform {
  required_version = ">= 1.0"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">=0.6.14"
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
      version = "2.1.0"
      source  = "go-gandi/gandi"
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

resource "libvirt_pool" "cluster_storage" {
  name = var.cluster_name
  type = "dir"
  path = "/var/lib/libvirt/images/${var.cluster_name}"
}

locals {
  additional_nodes = [local.lb_node, local.storage_node]
  all_nodes        = concat(local.additional_nodes, local.master_nodes, local.worker_nodes, local.bootstrap_nodes)
}

output "machines" {
  value = local.all_nodes
}
