locals {
  regions_list   = tolist(["ap-melbourne-1", "ap-sydney-1"])
  regions        = toset(local.regions_list)
  sorted_regions = sort(local.regions_list)

  base_cidr = "10.0.0.0/8"
  region_cidrs = {
    for idx, region in local.regions_list :
    region => cidrsubnet(local.base_cidr, 8, idx)
  }
  pairings = {
    for pair in setproduct(local.sorted_regions, local.sorted_regions) :
    "${pair[0]}-to-${pair[1]}" => {
      acceptor_region  = pair[0]
      requestor_region = pair[1]
    }
    if index(local.sorted_regions, pair[0]) < index(local.sorted_regions, pair[1])
  }
  acceptors_by_region = {
    for region in local.sorted_regions :
    region => [
      for k, v in local.pairings :
      v.requestor_region
      if v.acceptor_region == region
    ]
  }
  requestors_by_region = {
    for region in local.sorted_regions :
    region => [
      for k, v in local.pairings :
      v.acceptor_region
      if v.requestor_region == region
    ]
  }
  region_ocids = {
    for region in local.sorted_regions :
    region => {
      compartment_ocid         = data.sops_file.oci_creds_regional[region].data["compartment_ocid"]
      administrator_group_ocid = data.sops_file.oci_creds_regional[region].data["administrator_group_ocid"]
      tenancy_ocid             = data.sops_file.oci_creds_regional[region].data["tenancy_ocid"]
    }
  }

  vm_list = yamldecode(file("${path.module}/config/vms.yaml")).vms

  vms = { for vm in local.vm_list : vm.name => vm }

  vms_by_region = {
    for region in local.regions_list :
    region => {
      for vm in local.vm_list :
      vm.name => vm
      if vm.region == region
    }
  }

  firewall_config = yamldecode(file("${path.module}/config/firewall.yaml")).rules

  firewall_rules = flatten([
    for rule in local.firewall_config : [
      for role in rule.for_roles : {
        name        = rule.name
        description = rule.description
        direction   = rule.direction
        protocol    = rule.protocol
        ports       = rule.ports
        source      = rule.source
        destination = rule.destination
        role        = role
      }
    ]
  ])
}

locals {
  all_public_ips   = merge(module.vm_ap-sydney-1.public_ips, module.vm_ap-melbourne-1.public_ips)
  all_private_ips  = merge(module.vm_ap-sydney-1.private_ips, module.vm_ap-melbourne-1.private_ips)
  all_public_ipv6s = merge(module.vm_ap-sydney-1.public_ipv6s, module.vm_ap-melbourne-1.public_ipv6s)
  all_instance_ids = merge(module.vm_ap-sydney-1.instance_ids, module.vm_ap-melbourne-1.instance_ids)
  oci_ccm_region   = [for vm in local.vm_list : vm.region if vm.type == "cp"][0]
  nodes_with_ips = {
    for name, vm in local.vms :
    name => {
      name        = name
      role        = vm.type
      region      = vm.region
      provider_id = local.all_instance_ids[name]
      public_ipv6 = local.all_public_ipv6s[name]
      oci_lb      = vm.region == local.oci_ccm_region && contains(["cp", "sh"], vm.type)
    }
  }
}

output "vms" {
  value = [
    for name, vm in local.vms : {
      name        = name
      public_ip   = local.all_public_ips[name]
      private_ip  = local.all_private_ips[name]
      public_ipv6 = local.all_public_ipv6s[name]
      role        = vm.type
    }
  ]
}
