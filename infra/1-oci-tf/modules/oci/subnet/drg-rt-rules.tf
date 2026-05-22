resource "time_sleep" "drg_rt_rule_wait" {
  create_duration = "30s"
  depends_on      = [oci_core_remote_peering_connection.rpc]
}

# 1. Fetch attachments for each RPC
data "oci_core_drg_attachments" "rpc_attachments" {
  for_each = toset(var.rpc_acceptors_to_create)

  compartment_id  = var.compartment_ocid
  drg_id          = oci_core_drg.drg.id
  attachment_type = "REMOTE_PEERING_CONNECTION"
  network_id      = oci_core_remote_peering_connection.rpc[each.key].id
  depends_on      = [time_sleep.drg_rt_rule_wait]
}

# 2. Create a flat map of RPC name to attachment OCID
locals {
  rpc_attachment_ids = {
    for key in var.rpc_acceptors_to_create :
    key => data.oci_core_drg_attachments.rpc_attachments[key].drg_attachments[0].id
  }
}

# 3. Create the route rules
resource "oci_core_drg_route_table_route_rule" "drg_rt_rule" {
  for_each = toset(var.rpc_acceptors_to_create)

  drg_route_table_id         = oci_core_drg_route_table.drg_rt.id
  destination                = var.ipv4_of_all_other_regions[each.key]
  destination_type           = "CIDR_BLOCK"
  next_hop_drg_attachment_id = local.rpc_attachment_ids[each.key]
  depends_on                 = [time_sleep.drg_rt_rule_wait]
}

resource "oci_core_drg_route_table_route_rule" "drg_rt_rule_ipv6" {
  for_each = toset(var.rpc_acceptors_to_create)

  drg_route_table_id         = oci_core_drg_route_table.drg_rt.id
  destination                = var.ipv6_of_all_other_regions[each.key]
  destination_type           = "CIDR_BLOCK"
  next_hop_drg_attachment_id = local.rpc_attachment_ids[each.key]
  depends_on                 = [time_sleep.drg_rt_rule_wait]
}
