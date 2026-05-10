resource "oci_core_vcn" "vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = [var.priv_ipv4_cidr]
  is_ipv6enabled = true
}
resource "oci_core_internet_gateway" "igw" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.vcn.id
}
#resource "oci_core_subnet" "subnet" {
#  compartment_id    = var.compartment_ocid
#  vcn_id            = oci_core_vcn.vcn.id
#  ipv4cidr_blocks   = [cidrsubnet(var.priv_ipv4_cidr, 8, 1)]
#  ipv6cidr_blocks   = [cidrsubnet(oci_core_vcn.vcn.ipv6cidr_blocks[0], 8, 1)]
#  route_table_id    = oci_core_route_table.rt.id
#  security_list_ids = [oci_core_security_list.nsl.id]
#}

output "ipv6_cidr" {
  value = oci_core_vcn.vcn.ipv6cidr_blocks[0]
}
output "ipv4_cidr" {
  value = oci_core_vcn.vcn.cidr_blocks[0]
}
output "vcn_id" {
  value = oci_core_vcn.vcn.id
}
output "ig_id" {
  value = oci_core_internet_gateway.igw.id
}
