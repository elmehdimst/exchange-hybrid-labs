variable "username" {
  default     = "adminuser"
  description = "Admin username for all VMs"
}

variable "password" {
  default     = "Password1234!"
  description = "Admin password for all VMs"
}

variable "dc_domain_name" {
  default     = "demolabs50.local"
  description = "DC local domain name"
}

variable "custom_dns" {
  description = "The custom DNS IP address for the VNet"
  type        = string
  default     = ""
}

variable "create_exchange" {
  description = "Boolean to control the creation of the virtual machine"
  type        = bool
  default     = false
}