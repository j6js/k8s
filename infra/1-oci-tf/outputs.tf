resource "local_file" "output_json" {
  content = jsonencode({
    nodes = [
      for name, vm in local.vms : {
        name        = name
        public_ipv4 = local.all_public_ipv4s[name]
        private_ip  = local.all_private_ips[name]
        public_ipv6 = local.all_public_ipv6s[name]
        role        = vm.type
      }
    ]
    nlb_ingress = local.nlb_ingress
    vault_kms   = module.kms_for_hc_vault.kms_secrets
    ccm_secrets = local.ccm_secrets
  })
  filename = "${local.terragrunt_dir}/config/outputs/1-oci-tf.json"
}
