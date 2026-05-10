resource "tls_private_key" "ccm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "oci_identity_user" "ccm" {
  compartment_id = var.tenancy_ocid
  description    = "Service user for OCI Cloud Controller Manager"
  email          = "ccm@example.com"
  name           = var.service_user_name
}

resource "oci_identity_user_capabilities_management" "ccm" {
  user_id                      = oci_identity_user.ccm.id
  can_use_api_keys             = true
  can_use_auth_tokens          = false
  can_use_console_password     = false
  can_use_customer_secret_keys = false
  can_use_smtp_credentials     = false
}

resource "oci_identity_group" "ccm" {
  compartment_id = var.tenancy_ocid
  description    = "Group for OCI Cloud Controller Manager"
  name           = var.service_group_name
}

resource "oci_identity_user_group_membership" "ccm" {
  group_id = oci_identity_group.ccm.id
  user_id  = oci_identity_user.ccm.id
}

resource "oci_identity_user_group_membership" "ccm_admin" {
  group_id = oci_identity_group.ccm.id
  user_id  = var.admin_user_ocid
}

resource "time_sleep" "propagation_delay" {
  depends_on = [oci_identity_user_group_membership.ccm_admin]

  create_duration = "30s"
}

resource "oci_identity_api_key" "ccm" {
  key_value = tls_private_key.ccm.public_key_pem
  user_id   = oci_identity_user.ccm.id

  depends_on = [
    oci_identity_user_capabilities_management.ccm,
    oci_identity_user_group_membership.ccm,
    oci_identity_user_group_membership.ccm_admin,
    time_sleep.propagation_delay,
  ]
}

locals {
  ccm_secret = {
    "OCI_USER_OCID"    = oci_identity_user.ccm.id
    "OCI_FINGERPRINT"  = oci_identity_api_key.ccm.fingerprint
    "OCI_TENANCY_OCID" = var.tenancy_ocid
    "OCI_REGION"       = var.region
    "OCI_PRIVATE_KEY"  = tls_private_key.ccm.private_key_pem
    "OCI_SUBNET_OCID"  = var.subnet_ocid
    "OCI_COMPARTMENT_OCID" = var.compartment_ocid
    "OCI_VCN_OCID" = var.vcn_ocid
  }
}