variable "environment"  { type = string }
variable "location"     { type = string }
variable "project"      { type = string }
variable "owner"        { type = string }
variable "cost_center"  { type = string }
variable "admin_ssh_public_key" { type = string } # your own public key, e.g. file("~/.ssh/id_ed25519.pub")
