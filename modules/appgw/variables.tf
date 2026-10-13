variable "name"                { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id"           { type = string }
variable "backend_fqdn"        { type = string } # Container Apps environment default domain
variable "waf_mode"            { type = string }  # "Detection" (Phase 1) | "Prevention" (Phase 2 Step 13)
variable "tags"                 { type = map(string) }
