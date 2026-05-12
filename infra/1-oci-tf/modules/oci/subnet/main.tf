resource "oci_core_security_list" "sl" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_id

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 30000
      max = 32767
    }
  }
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = var.vcn_id
  ipv4cidr_blocks   = [cidrsubnet(var.priv_ipv4_cidr, 8, 1)]
  ipv6cidr_blocks   = [cidrsubnet(var.current_ipv6_cidr, 8, 1)]
  route_table_id    = oci_core_route_table.rt.id
  security_list_ids = [oci_core_security_list.sl.id]
}

resource "oci_core_route_table" "rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = var.vcn_id
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.ig_id
  }
  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = var.ig_id
  }

  dynamic "route_rules" {
    for_each = var.ipv6_of_all_other_regions
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_drg.drg.id
    }
  }
  dynamic "route_rules" {
    for_each = var.ipv4_of_all_other_regions
    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = oci_core_drg.drg.id
    }
  }
}

resource "oci_core_drg" "drg" {
  compartment_id = var.compartment_ocid
}
resource "oci_core_drg_route_table" "drg_rt" {
  drg_id = oci_core_drg.drg.id
}
resource "oci_core_drg_attachment" "drg_attachment" {
  drg_id             = oci_core_drg.drg.id
  vcn_id             = var.vcn_id
  drg_route_table_id = oci_core_drg_route_table.drg_rt.id
}

resource "oci_core_remote_peering_connection" "rpc" {
  for_each       = toset(var.rpc_acceptors_to_create)
  compartment_id = var.compartment_ocid
  drg_id         = oci_core_drg.drg.id
  display_name   = "to-${each.key}"
}

output "subnet_id" {
  value = oci_core_subnet.subnet.id
}
output "ipv6_cidr_block" {
  value = oci_core_subnet.subnet.ipv6cidr_blocks[0]
}
output "drg_id" {
  value = oci_core_drg.drg.id
}
output "drg_route_table_id" {
  value = oci_core_drg_route_table.drg_rt.id
}
output "rpc_ocids" {
  value = { for k, v in oci_core_remote_peering_connection.rpc : k => v.id }
}
output "rpc_acceptors_by_region" {
  value = { for k in var.rpc_acceptors_to_create : k => var.region_name }
}
