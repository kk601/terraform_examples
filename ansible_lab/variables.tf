variable "admin_username" {
  type    = string
  default = "azureuser"
}
variable "linux_vm_count" {
  type    = number
  default = 2
}
variable "windows_vm_count" {
  type    = number
  default = 1
}