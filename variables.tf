variable "master_nodes" {
  type    = number
  default = 3
}

variable "worker_nodes" {
  type    = number
  default = 3
}

variable "bootstrap_nodes" {
  type    = number
  default = 1
}

variable "pool_name" {
  type    = string
  default = "default"
}

variable "volume_format" {
  type    = string
  default = "qcow2"
}

variable "centos_image" {
  type    = string
  default = "centos-stream-8"
}

variable "coreos_image" {
  type    = string
  default = "rhcos-4.7.0-x86_64-qemu.x86_64"
}

variable "cluster_name" {
  type    = string
  default = "ocp4"
}

variable "base_domain" {
  type    = string
  default = "ocp.lab"
}

variable "network_name" {
  type    = string
  default = "lab"
}

variable "network_ip_range" {
  type    = string
  default = "192.168.7.0/24"
}

variable "network_mac_format" {
  type    = string
  default = "02:01:07:00:07:%02x"
}

variable "public_cluster_ip" {
  type = string
}

variable "master_disk_size" {
  type    = number
  default = 120 * 1024 * 1024 * 1024
}

variable "master_vcpu" {
  type    = number
  default = 4
}

variable "master_memory_size" {
  type    = number
  default = 16 * 1024
}

variable "lb_disk_size" {
  type    = number
  default = 10 * 1024 * 1024 * 1024
}

variable "lb_vcpu" {
  type    = number
  default = 2
}

variable "lb_memory_size" {
  type    = number
  default = 4 * 1024
}

variable "storage_disk_size" {
  type    = number
  default = 120 * 1024 * 1024 * 1024
}

variable "storage_vcpu" {
  type    = number
  default = 2
}

variable "storage_memory_size" {
  type    = number
  default = 8 * 1024
}

variable "worker_disk_size" {
  type    = number
  default = 120 * 1024 * 1024 * 1024
}

variable "worker_vcpu" {
  type    = number
  default = 2
}

variable "worker_memory_size" {
  type    = number
  default = 8 * 1024
}

variable "bootstrap_disk_size" {
  type    = number
  default = 120 * 1024 * 1024 * 1024
}

variable "bootstrap_vcpu" {
  type    = number
  default = 4
}

variable "bootstrap_memory_size" {
  type    = number
  default = 16 * 1024
}

variable "acme_account_email" {
  type = string
}

locals {
  master_format  = "${var.cluster_name}-master-%02d"
  worker_format  = "${var.cluster_name}-worker-%02d"
  bootstrap_name = "${var.cluster_name}-bootstrap"
  storage_name   = "${var.cluster_name}-storage"
  lb_name        = "${var.cluster_name}-lb"
  network_domain = "${var.cluster_name}.${var.base_domain}"
}
