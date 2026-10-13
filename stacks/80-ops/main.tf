locals {
  tags = {
    project = var.project, env = var.environment, owner = var.owner
    cost_center = var.cost_center, managed_by = "terraform", phase = "phase1"
  }
  rg_ops = local.governance_resource_group_names["ops"]
}

# LLD 10.4 — cloud-init bootstraps Ansible on first boot (file lives in
# ansible/files/cloud-init.yaml, see Implementation Guide Step 8)
data "local_file" "cloud_init" {
  filename = "${path.module}/../../../ansible/files/cloud-init.yaml"
}

module "ops_vm" {
  source                  = "../../modules/vm-linux"
  name                      = "vm-ops-${var.environment}-cin-01"
  location                    = var.location
  resource_group_name          = local.rg_ops
  subnet_id                      = local.ops_subnet_ids["snet-runner"]
  admin_ssh_public_key              = var.admin_ssh_public_key
  cloud_init_rendered                 = base64encode(data.local_file.cloud_init.content)
  tags                                   = local.tags
}

# LLD 4.4 — id-ops-vm-dev gets Key Vault Secrets User
resource "azurerm_role_assignment" "ops_vm_kv" {
  scope                = local.keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id           = module.ops_vm.principal_id
}
