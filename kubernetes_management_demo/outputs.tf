output "app_load_balancer_ip" {
  value = kubernetes_service.services["frontend-external"].status[0]["load_balancer"][0]["ingress"][0].ip
}
output "msg" {
  value = "Specifiy kubeconfig used for cluster connection with: export KUBECONFIG=${local_sensitive_file.kubeconfig.filename}"
}