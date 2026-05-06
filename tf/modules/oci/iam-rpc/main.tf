resource "oci_identity_policy" "requestors" {
  for_each       = toset(var.requestors)
  compartment_id = var.region_ocids[var.region_name]["tenancy_ocid"]
  name           = "accept-rpc-to-${each.key}"
  description    = "Allow RPC to accept peering to the ${each.key} region"
  statements = [
    "Define tenancy Acceptor as ${var.region_ocids[each.key]["tenancy_ocid"]}",
    "Allow group id ${var.region_ocids[(var.region_name)]["administrator_group_ocid"]} to manage remote-peering-from in compartment id ${var.compartment_ocid}",
    "Endorse group id ${var.region_ocids[(var.region_name)]["administrator_group_ocid"]} to manage remote-peering-to in tenancy Acceptor"
  ]
}
resource "oci_identity_policy" "acceptors" {
  for_each       = toset(var.acceptors)
  name           = "accept-rpc-from-${each.key}"
  description    = "Allow RPC to accept peering from the ${each.key} region"
  compartment_id = var.region_ocids[var.region_name]["tenancy_ocid"]

  statements = [
    "Define tenancy Requestor as ${var.region_ocids[each.key]["tenancy_ocid"]}",
    "Define group requestorGroup as ${var.region_ocids[each.key]["administrator_group_ocid"]}",
    "Admit group requestorGroup of tenancy Requestor to manage remote-peering-to in compartment id ${var.compartment_ocid}"
  ]
}
