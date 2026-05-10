variable "vcn_id" {
  type        = string
  description = "Private IPv4 CIDR for the OCI VCN"
}
variable "ig_id" {
  type        = string
  description = "OCID of the internet gateway"
}
variable "region_ocids" {
  type        = map(map(string))
  description = "Object containing region names as keys and Administrator Group, Compartment, and Tenancy OCIDs as values"
}
variable "region_name" {
  type        = string
  description = "Name of the region"
}
variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment to create resources in"
}
variable "rpc_acceptors_to_create" {
  type        = list(string)
  description = "List of requestor regions to create RPCs for"
}
variable "priv_ipv4_cidr" {
  type        = string
  description = "Private IPv4 CIDR for the OCI VCN, usually a /16"
}
variable "current_ipv6_cidr" {
  type        = string
  description = "IPv6 CIDR for the OCI VCN, usually a /56 and provided by Oracle"
}
variable "ipv4_of_all_other_regions" {
  type        = map(string)
  description = "List of all other region's IPv4 CIDRs to be used for routing, excluding the current region's IPv4 CIDR"
}
variable "ipv6_of_all_other_regions" {
  type        = map(string)
  description = "List of all other region's IPv6 CIDRs to be used for routing, excluding the current region's IPv6 CIDR"
}
