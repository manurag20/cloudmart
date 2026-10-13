variable "server_name"          { type = string }
variable "database_name"        { type = string }
variable "location"             { type = string }
variable "resource_group_name"  { type = string }
variable "subnet_id"            { type = string }
variable "private_dns_zone_id"  { type = string }
variable "aad_admin_object_id"  { type = string }
variable "aad_admin_login"      { type = string }
variable "min_vcore" {
  type    = number
  default = 0.5
}
variable "max_vcore" {
  type    = number
  default = 1
}
variable "auto_pause_delay_minutes" {
  type    = number
  default = 60
}
variable "tags"                 { type = map(string) }
