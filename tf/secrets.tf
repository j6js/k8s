data "sops_file" "oci_creds_regional" {
  for_each    = local.regions
  source_file = "${path.module}/.sops/oracle_${each.key}.yaml"
}
