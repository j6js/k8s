output "ccm_group_ocid" {
  value = oci_identity_group.ccm.id
  sensitive = true
}

output "ccm_secrets" {
  value = local.ccm_secret
  sensitive = true
}
