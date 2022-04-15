# microservices_deployment_demo
This terraform example deploys [Online Boutique microservices demo application](https://github.com/GoogleCloudPlatform/microservices-demo) on Azure Kubernetes Service.
---
# Usage:
## Apply terraform configuration
1. Initialize terraform: `terraform init`
2. Apply configuration: `terraform apply`
3. (optional) Specifiy kubeconfig used for cluster connection: 
   `export KUBECONFIG=~/.kube/kubernetes_management_demo_kubeconfig`
    > Remeber to use kubectl with `--namespace onlineboutique` parameter

---
