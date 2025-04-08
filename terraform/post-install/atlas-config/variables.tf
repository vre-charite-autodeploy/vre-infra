variable "atlas_namespace" {
  type    = string
  default = "utility"
}

variable "atlas_admin_username" {
  type    = string
  default = "admin"
}

variable "atlas_admin_password" {
  type      = string
  default   = "admin"
  sensitive = true
}

variable "atlas_name" {
  type    = string
  default = "atlas"
}

variable "atlas_port" {
  type    = number
  default = 21000
}
