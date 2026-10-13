variable "name"                { type = string }
variable "location"            { type = string }
variable "resource_group_name" { type = string }
variable "address_space"       { type = list(string) }
variable "tags"                { type = map(string) }

# map(subnet_key => { address_prefixes, delegation_service = optional, private_endpoint_policies = optional bool })
variable "subnets" {
  type = map(object({
    address_prefixes          = list(string)
    delegation_service        = optional(string)
    private_endpoint_policies = optional(bool, false)
  }))
}

variable "hub_vnet_id"   { type = string }
variable "hub_vnet_name" { type = string }
variable "hub_resource_group_name" { type = string }
