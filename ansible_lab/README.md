# ansible_lab
This terraform example creates ansible lab environment with linux/windows virtual machines.
---
# Usage:
## Apply terraform configuration
1. Initialize terraform: `terraform init`
2. Apply configuration: `terraform apply`
3. Test: `ansible-playbook -i inventory/hosts.ini playbooks/ping_all_vms.yml`

---
## Replace vm:
```terraform apply -replace="azurerm_linux_virtual_machine.linux_vm[0]" -auto-approve```

---
## Apply install_postgresql_linux playbook:
Install postgreSQL

```ansible-playbook -i inventory/hosts.ini  playbooks/install_postgresql_linux.yml```

---
## Apply install_postgresql_linux playbook with pgbackup tool installed:
pgbackup is CLI tool for postgreSQL database backup([project page](https://github.com/kk601/pgbackup))

```ansible-playbook -i inventory/hosts.ini  playbooks/install_postgresql_linux.yml -e "Import_test_db=yes Install_pgbackup=yes Pgbackup_cloud_drivers_support=yes"```

### Test pgbackup tool on host:
```pgbackup --driver azure postgres://postgres@:5432/test_db dump.sql```

---
