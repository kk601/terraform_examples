output "nginx_public_ip" {
  value = module.nginx.public_ip_address
}
output "nginx_dns_name" {
  value = module.nginx.public_ip_dns_name
}
output "internal_web_servers_password" {
  value = nonsensitive(random_password.password.result)
}