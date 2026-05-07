resource "oci_identity_dynamic_group" "ccm_nodes" {
  compartment_id = var.tenancy_ocid
  name           = "k8s-oci-ccm-${var.region_name}"
  description    = "Instances allowed to use instance principals for OCI CCM in ${var.region_name}"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_ocid}'}"
}

resource "oci_identity_policy" "ccm" {
  compartment_id = var.tenancy_ocid
  name           = "k8s-oci-ccm-${var.region_name}"
  description    = "Allow Kubernetes OCI CCM to manage load balancers in ${var.region_name}"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm_nodes.name} to read instance-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm_nodes.name} to use virtual-network-family in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm_nodes.name} to manage network-load-balancers in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm_nodes.name} to manage load-balancers in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm_nodes.name} to manage network-security-groups in compartment id ${var.compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm_nodes.name} to manage security-lists in compartment id ${var.compartment_ocid}"
  ]
}

