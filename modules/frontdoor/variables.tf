variable "profile_name"        { type = string }
variable "resource_group_name" { type = string }
variable "origin_host"         { type = string } # Application Gateway public IP / FQDN
variable "waf_mode"            { type = string }
variable "tags"                 { type = map(string) }
