variable "name"                { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id"           { type = string }
variable "admin_username" {
  type    = string
  default = "azureuser"
}
variable "admin_ssh_public_key" { type = string }
variable "cloud_init_rendered" { type = string } # base64 content from ../ansible-cloudmart/files/cloud-init.yaml
variable "tags"                 { type = map(string) }
