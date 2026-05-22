# Copyright Jackson Kelly 2026
# SPDX-License-Identifier: BUSL-1.1

data "sops_file" "oci_creds_regional" {
  for_each    = local.regions
  source_file = "${local.terragrunt_dir}/../.sops/oracle_${each.key}.yaml"
}
