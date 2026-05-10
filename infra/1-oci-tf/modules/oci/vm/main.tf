data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_ocid
}

locals {
  roles = ["cp", "sh", "wk"]

  local_vcn_cidrs = [var.local_ipv4_cidr, var.local_ipv6_cidr]
  peer_vcn_cidrs  = concat(values(var.peer_ipv4_cidrs), values(var.peer_ipv6_cidrs))

  cidr_scopes = {
    internet  = ["0.0.0.0/0", "::/0"]
    vcn       = local.local_vcn_cidrs
    peer_vcns = local.peer_vcn_cidrs
    all_vcns  = concat(local.local_vcn_cidrs, local.peer_vcn_cidrs)
  }

  ingress_rules = flatten([
    for idx, rule in var.firewall_rules : [
      for cidr_idx, cidr in lookup(local.cidr_scopes, rule.source, [rule.source]) :
      merge(rule, {
        cidr = cidr
        key  = "${idx}-${cidr_idx}-${rule.role}-${rule.name}"
      })
    ]
    if rule.direction == "ingress"
  ])

  egress_rules = flatten([
    for idx, rule in var.firewall_rules : [
      for cidr_idx, cidr in lookup(local.cidr_scopes, rule.destination, [rule.destination]) :
      merge(rule, {
        cidr = cidr
        key  = "${idx}-${cidr_idx}-${rule.role}-${rule.name}"
      })
    ]
    if rule.direction == "egress"
  ])
}

resource "oci_core_network_security_group" "nsg" {
  for_each       = toset(local.roles)
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_id
  display_name   = "nsg-${each.value}"
}

resource "oci_core_network_security_group_security_rule" "nsg_ingress_tcp" {
  for_each = {
    for rule in local.ingress_rules :
    rule.key => rule
    if rule.direction == "ingress" && rule.protocol == "tcp" && length(rule.ports) > 0
  }
  network_security_group_id = oci_core_network_security_group.nsg[each.value.role].id
  description               = each.value.description
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "CIDR_BLOCK"
  source                    = each.value.cidr

  tcp_options {
    destination_port_range {
      min = each.value.ports[0]
      max = each.value.ports[length(each.value.ports) - 1]
    }
  }
}

resource "oci_core_network_security_group_security_rule" "nsg_ingress_udp" {
  for_each                  = { for rule in local.ingress_rules : rule.key => rule if rule.direction == "ingress" && rule.protocol == "udp" && length(rule.ports) > 0 }
  network_security_group_id = oci_core_network_security_group.nsg[each.value.role].id
  description               = each.value.description
  direction                 = "INGRESS"
  protocol                  = "17"
  source_type               = "CIDR_BLOCK"
  source                    = each.value.cidr

  udp_options {
    destination_port_range {
      min = each.value.ports[0]
      max = each.value.ports[length(each.value.ports) - 1]
    }

  }
}

resource "oci_core_network_security_group_security_rule" "nsg_ingress_all" {
  for_each                  = { for rule in local.ingress_rules : rule.key => rule if rule.direction == "ingress" && rule.protocol == "all" }
  network_security_group_id = oci_core_network_security_group.nsg[each.value.role].id
  description               = each.value.description
  direction                 = "INGRESS"
  protocol                  = "all"
  source_type               = "CIDR_BLOCK"
  source                    = each.value.cidr
}

resource "oci_core_network_security_group_security_rule" "nsg_egress_tcp" {
  for_each                  = { for rule in local.egress_rules : rule.key => rule if rule.direction == "egress" && rule.protocol == "tcp" && length(rule.ports) > 0 }
  network_security_group_id = oci_core_network_security_group.nsg[each.value.role].id
  description               = each.value.description
  direction                 = "EGRESS"
  protocol                  = "6"
  destination_type          = "CIDR_BLOCK"
  destination               = each.value.cidr

  tcp_options {
    destination_port_range {
      min = each.value.ports[0]
      max = each.value.ports[length(each.value.ports) - 1]
    }
  }
}

resource "oci_core_network_security_group_security_rule" "nsg_egress_udp" {
  for_each                  = { for rule in local.egress_rules : rule.key => rule if rule.direction == "egress" && rule.protocol == "udp" && length(rule.ports) > 0 }
  network_security_group_id = oci_core_network_security_group.nsg[each.value.role].id
  description               = each.value.description
  direction                 = "EGRESS"
  protocol                  = "17"
  destination_type          = "CIDR_BLOCK"
  destination               = each.value.cidr

  udp_options {
    destination_port_range {
      min = each.value.ports[0]
      max = each.value.ports[length(each.value.ports) - 1]
    }
  }
}

resource "oci_core_network_security_group_security_rule" "nsg_egress_all" {
  for_each                  = { for rule in local.egress_rules : rule.key => rule if rule.direction == "egress" && rule.protocol == "all" }
  network_security_group_id = oci_core_network_security_group.nsg[each.value.role].id
  description               = each.value.description
  direction                 = "EGRESS"
  protocol                  = "all"
  destination_type          = "CIDR_BLOCK"
  destination               = each.value.cidr
}

resource "oci_core_instance" "vm" {
  for_each = var.vms

  compartment_id                      = var.compartment_ocid
  display_name                        = each.key
  availability_domain                 = data.oci_identity_availability_domains.this.availability_domains[0].name
  shape                               = var.shape
  is_pv_encryption_in_transit_enabled = true

  create_vnic_details {
    subnet_id        = var.subnet_id
    assign_public_ip = false
    assign_ipv6ip    = false
    nsg_ids          = [oci_core_network_security_group.nsg[each.value.type].id]
  }

  launch_options {
    firmware                            = "UEFI_64"
    is_pv_encryption_in_transit_enabled = true
    network_type                        = "PARAVIRTUALIZED"
  }

  shape_config {
    ocpus         = each.value.cpu
    memory_in_gbs = each.value.ram
  }

  source_details {
    source_type             = "image"
    source_id               = var.image_id
    boot_volume_size_in_gbs = each.value.disk
  }
}

data "oci_core_vnic_attachments" "vm" {
  for_each       = var.assign_ipv6ip ? var.vms : tomap({})
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.vm[each.key].id
}

resource "oci_core_ipv6" "vm" {
  for_each  = var.assign_ipv6ip ? var.vms : tomap({})
  lifetime  = "RESERVED"
  subnet_id = var.subnet_id
  vnic_id   = data.oci_core_vnic_attachments.vm[each.key].vnic_attachments[0].vnic_id
}
data "oci_core_private_ips" "privip" {
  for_each = var.assign_public_ip ? var.vms : tomap({})
  vnic_id  = data.oci_core_vnic_attachments.vm[each.key].vnic_attachments[0].vnic_id
}
resource "oci_core_public_ip" "vm" {
  compartment_id = var.compartment_ocid
  for_each       = var.assign_public_ip ? var.vms : tomap({})
  lifetime       = "RESERVED"
  private_ip_id  = data.oci_core_private_ips.privip[each.key].private_ips[0].id
}
output "instance_ids" {
  value = { for k, v in oci_core_instance.vm : k => v.id }
}

output "private_ips" {
  value = { for k, v in oci_core_instance.vm : k => v.private_ip }
}

output "public_ips" {
  value = { for k, v in oci_core_public_ip.vm : k => v.ip_address }
}

output "public_ipv6s" {
  value = { for k, v in oci_core_ipv6.vm : k => v.ip_address }
}
