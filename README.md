# Testing Various Databases Options

## Get Azure CLI

https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-yum?view=azure-cli-latest

Then

```bash
az login
```

## Terraform

```bash
cd terrafrom
terrafrom init
terrafrom plan
terraform apply
```

## Ansible

```
cd ansible
echo -e "[db-server]\n${VM_IP}\n" > hosts
ansible -m ping -i hosts
```

