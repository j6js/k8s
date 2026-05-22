data "sops_file" "oci_creds_regional" {
  for_each    = local.regions
  source_file = "${local.terragrunt_dir}/../.sops/oracle_${each.key}.yaml"
}
