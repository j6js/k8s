variable "requestor_region_names" {
  description = "Map of acceptor region -> region name for peering"
  type        = map(string)
  default     = {}
}
variable "all_rpc_ocids" {
  description = "Map of region -> RPC OCID map for looking up peer RPC OCIDs"
  type        = map(map(string))
  default     = {}
}
variable "ipv4_of_all_other_regions" {
  description = "Map of peer region name -> IPv4 VCN CIDR"
  type        = map(string)
  default     = {}
}
variable "ipv6_of_all_other_regions" {
  description = "Map of peer region name -> IPv6 VCN CIDR"
  type        = map(string)
  default     = {}
}
variable "region_name" {
  description = "Name of this region (the requestor)"
  type        = string
}
variable "drg_id" {
  description = "DRG OCID to attach route rules to"
  type        = string
}
variable "drg_route_table_id" {
  description = "DRG route table OCID"
  type        = string
}
variable "compartment_ocid" {
  description = "Compartment OCID"
  type        = string
}
