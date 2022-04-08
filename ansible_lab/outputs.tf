output "linux_vm_hostnames" {
    value = azurerm_linux_virtual_machine.linux_vm[*].name
}
output "windows_vm_hostnames" {
    value = azurerm_windows_virtual_machine.windows_vm[*].name
}