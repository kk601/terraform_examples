# ansible_lab
This terraform example creates ansible lab environment with linux/windows virtual machines.
## Usage
1. Initialize terraform: `terraform init`
2. Apply configuration: `terraform apply`
3. Test: `ansible-playbook -i inventory/hosts.ini playbooks/ping_all_vms.yml`
   