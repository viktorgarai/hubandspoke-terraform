variable "location" {
  default = "westeurope"
}

variable "resource_group_name" {
  default = "rg-hub-spoke"
}

variable "vm_admin_username" {
  description = "Admin username for the VMs"
  type        = string
}

variable "vm_admin_password" {
  description = "Admin password for the VMs"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    environment = "dev"
    project     = "hub-spoke"
  }
}