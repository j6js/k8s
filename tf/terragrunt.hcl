terraform {
  include_in_copy = [
    "talos/**",
    ".sops",
    "config/**"
  ]
}

remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    path = "${get_terragrunt_dir()}/terraform.tfstate"
  }
}


locals {
  regions              = yamldecode(file("${get_terragrunt_dir()}/config/regions.yaml"))
  regions_list         = local.regions
  sorted_regions       = sort(local.regions_list)
  regions_set          = toset(local.regions_list)
  base_cidr            = "10.0.0.0/8"
  region_cidrs         = { for idx, region in local.regions_list : region => cidrsubnet(local.base_cidr, 8, idx) }
  pairings             = { for pair in setproduct(local.sorted_regions, local.sorted_regions) : "${pair[0]}-to-${pair[1]}" => { acceptor_region = pair[0], requestor_region = pair[1] } if index(local.sorted_regions, pair[0]) < index(local.sorted_regions, pair[1]) }
  acceptors_by_region  = { for region in local.sorted_regions : region => [for k, v in local.pairings : v.requestor_region if v.acceptor_region == region] }
  requestors_by_region = { for region in local.sorted_regions : region => [for k, v in local.pairings : v.acceptor_region if v.requestor_region == region] }
}

generate "modules" {
  path      = "modules.dynamic.tf"
  if_exists = "overwrite_terragrunt"
  contents = templatefile("${get_terragrunt_dir()}/modules.dynamic.tf.tftpl", {
    regions              = local.regions,
    regions_list         = local.regions_list,
    sorted_regions       = local.sorted_regions,
    region_cidrs         = local.region_cidrs,
    acceptors_by_region  = local.acceptors_by_region,
    requestors_by_region = local.requestors_by_region,
    terragrunt_dir       = get_terragrunt_dir()
  })
}

generate "provider" {
  path      = "provider.dynamic.tf"
  if_exists = "overwrite_terragrunt"
  contents  = templatefile("${get_terragrunt_dir()}/provider.dynamic.tf.tftpl", { regions = local.regions, regions_list = local.regions_list, terragrunt_dir = get_terragrunt_dir() })
}
generate "template" {
  path      = "template.dynamic.tf"
  if_exists = "overwrite_terragrunt"
  contents  = templatefile("${get_terragrunt_dir()}/template.dynamic.tf.tftpl", { regions = local.regions, regions_list = local.regions_list, terragrunt_dir = get_terragrunt_dir() })
}
