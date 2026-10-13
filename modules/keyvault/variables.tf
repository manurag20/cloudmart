variable "name"                { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "tenant_id"           { type = string }
variable "subnet_id"           { type = string }
variable "private_dns_zone_id" { type = string }
variable "purge_protection_enabled" {
  type    = bool
  default = false # Phase 1 = false, Phase 2 Step 13 flips to true
}
variable "tags"                { type = map(string) }
