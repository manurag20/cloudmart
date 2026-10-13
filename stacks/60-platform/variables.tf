variable "environment" { type = string }
variable "location"    { type = string }
variable "project"     { type = string }
variable "owner"       { type = string }
variable "cost_center" { type = string }

variable "image_tag" {
  type    = string
  default = "latest" # overridden by app-cd.yml with the commit SHA at deploy time
}
