variable "admin_username" {
  description = "The admin username for the VMs"
  type        = string
  default     = "adminuser"
}

variable "admin_password" {
  description = "The admin password for the VMs"
  type        = string
  sensitive   = true
}