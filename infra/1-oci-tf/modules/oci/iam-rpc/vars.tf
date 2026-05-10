variable "compartment_ocid" {
  type        = string
  description = "The OCID of the compartment to create the policy in"
}
variable "acceptors" {
  type    = list(string)
  default = []
}
variable "requestors" {
  type    = list(string)
  default = []
}
variable "region_ocids" {
  type = map(object({
    tenancy_ocid             = string
    administrator_group_ocid = string
  }))
  default = {}
}
variable "region_name" {
  type        = string
  description = ""
}
