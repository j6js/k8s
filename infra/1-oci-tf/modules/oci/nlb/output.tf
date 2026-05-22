output "id" {
  value = oci_network_load_balancer_network_load_balancer.ingress.id
}

output "public_ipv4" {
  value = [for ip in oci_network_load_balancer_network_load_balancer.ingress.ip_addresses : ip if ip.is_public && ip.ip_version == "IPV4"][0].ip_address
}

output "public_ipv6" {
  value = [for ip in oci_network_load_balancer_network_load_balancer.ingress.ip_addresses : ip if ip.is_public && ip.ip_version == "IPV6"][0].ip_address
}

output "private_ipv4" {
  value = null
}

output "dns_targets" {
  value = compact([
    [for ip in oci_network_load_balancer_network_load_balancer.ingress.ip_addresses : ip if ip.is_public && ip.ip_version == "IPV4"][0].ip_address,
    [for ip in oci_network_load_balancer_network_load_balancer.ingress.ip_addresses : ip if ip.is_public && ip.ip_version == "IPV6"][0].ip_address,
  ])
}
