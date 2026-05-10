resource "oci_identity_policy" "ccm_load_balancer" {
  compartment_id = var.compartment_ocid
  name           = "ccm-lb-${var.region_name}"
  description    = "Allow CCM to manage load balancers in ${var.region_name}"
  statements = [
    "Allow group id ${var.group_ocid} to manage load-balancers in compartment id ${var.compartment_ocid}",
    "Allow group id ${var.group_ocid} to manage network-load-balancers in compartment id ${var.compartment_ocid}",
  ]
}
resource "oci_identity_policy" "ccm_vm" {
  compartment_id = var.compartment_ocid
  name           = "ccm-vm-${var.region_name}"
  description    = "Allow CCM to read virtual machines in ${var.region_name}"
  statements = [
    "Allow group id ${var.group_ocid} to read instance-family in compartment id ${var.compartment_ocid}",
    "Allow group id ${var.group_ocid} to use vnics in compartment id ${var.compartment_ocid}",
    "Allow group id ${var.group_ocid} to read vnic-attachments in compartment id ${var.compartment_ocid}",
  ]
}
resource "oci_identity_policy" "ccm_nsg" {
  compartment_id = var.compartment_ocid
  name           = "ccm-nsg-${var.region_name}"
  description    = "Allow CCM to manage network security groups in ${var.region_name}"
  statements = [
    "Allow group id ${var.group_ocid} to manage security-lists in compartment id ${var.compartment_ocid}",
    "Allow group id ${var.group_ocid} to use network-security-groups in compartment id ${var.compartment_ocid}",
  ]
}

resource "oci_identity_policy" "ccm_vcn" {
  compartment_id = var.compartment_ocid
  name           = "ccm-vcn-${var.region_name}"
  description    = "Allow CCM to read VCN resources in ${var.region_name}"
  statements = [
    "Allow group id ${var.group_ocid} to use vcns in compartment id ${var.compartment_ocid}",
    "Allow group id ${var.group_ocid} to use subnets in compartment id ${var.compartment_ocid}",
    "Allow group id ${var.group_ocid} to read virtual-network-family in compartment id ${var.compartment_ocid}",
    "Allow group id ${var.group_ocid} to use private-ips in compartment id ${var.compartment_ocid}",
  ]
}

resource "oci_identity_policy" "ccm_route_tables" {
  compartment_id = var.compartment_ocid
  name           = "ccm-route-tables-${var.region_name}"
  description    = "Allow CCM to manage route tables in ${var.region_name}"
  statements = [
    "Allow group id ${var.group_ocid} to manage route-tables in compartment id ${var.compartment_ocid}",
  ]
}
