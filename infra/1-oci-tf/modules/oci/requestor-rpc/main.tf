resource "time_sleep" "drg_attachment_wait" {
  create_duration = "30s"
  depends_on      = [oci_core_remote_peering_connection.requestor_rpc]
}

resource "oci_core_remote_peering_connection" "requestor_rpc" {
  for_each         = toset(keys(var.requestor_region_names))
  compartment_id   = var.compartment_ocid
  drg_id           = var.drg_id
  display_name     = "from-${each.key}"
  peer_id          = var.all_rpc_ocids[each.key][var.region_name]
  peer_region_name = var.requestor_region_names[each.key]
}

data "oci_core_drg_attachments" "requestor_rpc_attachments" {
  for_each        = toset(keys(var.requestor_region_names))
  compartment_id  = var.compartment_ocid
  drg_id          = var.drg_id
  attachment_type = "REMOTE_PEERING_CONNECTION"
  network_id      = oci_core_remote_peering_connection.requestor_rpc[each.key].id
  depends_on      = [time_sleep.drg_attachment_wait]
}

locals {
  requestor_rpc_attachment_ids = {
    for key in keys(var.requestor_region_names) :
    key => data.oci_core_drg_attachments.requestor_rpc_attachments[key].drg_attachments[0].id
  }
}

resource "oci_core_drg_route_table_route_rule" "requestor_drg_rt_rule" {
  for_each                   = toset(keys(var.requestor_region_names))
  drg_route_table_id         = var.drg_route_table_id
  destination                = var.ipv4_of_all_other_regions[each.key]
  destination_type           = "CIDR_BLOCK"
  next_hop_drg_attachment_id = local.requestor_rpc_attachment_ids[each.key]
  depends_on                 = [time_sleep.drg_attachment_wait]
}

resource "oci_core_drg_route_table_route_rule" "requestor_drg_rt_rule_ipv6" {
  for_each                   = toset(keys(var.requestor_region_names))
  drg_route_table_id         = var.drg_route_table_id
  destination                = var.ipv6_of_all_other_regions[each.key]
  destination_type           = "CIDR_BLOCK"
  next_hop_drg_attachment_id = local.requestor_rpc_attachment_ids[each.key]
  depends_on                 = [time_sleep.drg_attachment_wait]
}
