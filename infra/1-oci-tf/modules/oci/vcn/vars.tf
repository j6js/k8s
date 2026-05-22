variable "priv_ipv4_cidr" {
  type        = string
  description = "Private IPv4 CIDR for the OCI VCN"
}
variable "compartment_ocid" {
  type        = string
  description = "OCID of the compartment to create resources in"
}
