locals {
  active_backends = {
    for name, backend in var.backends : name => backend
    if contains(var.backend_roles, backend.role)
  }

  ipv4_listener_keys = var.enable_ipv4_backends ? var.listeners : {}
  ipv6_listener_keys = var.enable_ipv6_backends ? var.listeners : {}

  ipv4_backend_registrations = merge([
    for listener_name, listener in var.listeners : {
      for backend_name, backend in local.active_backends :
      "${listener_name}-${backend_name}" => {
        listener_name = listener_name
        backend_name  = backend_name
        port          = listener.backend_port
        ip_address    = backend.private_ipv4
      }
    }
  ]...)

  ipv6_backend_registrations = merge([
    for listener_name, listener in var.listeners : {
      for backend_name, backend in local.active_backends :
      "${listener_name}-${backend_name}" => {
        listener_name = listener_name
        backend_name  = backend_name
        port          = listener.backend_port
        ip_address    = backend.public_ipv6
      }
    }
  ]...)
}

resource "oci_core_ipv6" "nlb_ipv6" {
  subnet_id = var.subnet_id
  lifetime  = "RESERVED"
}

resource "oci_core_public_ip" "nlb_ipv4" {
  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
}

resource "oci_network_load_balancer_network_load_balancer" "ingress" {
  compartment_id                 = var.compartment_id
  display_name                   = "ingress-nlb-${var.region}"
  subnet_id                      = var.subnet_id
  nlb_ip_version                 = "IPV4_AND_IPV6"
  is_private                     = false

  reserved_ips {
    id = oci_core_ipv6.nlb_ipv6.id
  }

  reserved_ips {
    id = oci_core_public_ip.nlb_ipv4.id
  }
}

resource "oci_network_load_balancer_backend_set" "ipv4" {
  for_each                 = local.ipv4_listener_keys
  name                     = "${each.key}_ipv4"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  policy                   = "FIVE_TUPLE"
  ip_version               = "IPV4"

  health_checker {
    protocol           = "TCP"
    port               = each.value.backend_port
    interval_in_millis = 10000
    timeout_in_millis  = 3000
    retries            = 3
  }
}

resource "oci_network_load_balancer_backend_set" "ipv6" {
  for_each                 = local.ipv6_listener_keys
  name                     = "${each.key}_ipv6"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  policy                   = "FIVE_TUPLE"
  ip_version               = "IPV6"

  health_checker {
    protocol           = "TCP"
    port               = each.value.backend_port
    interval_in_millis = 10000
    timeout_in_millis  = 3000
    retries            = 3
  }
}

resource "oci_network_load_balancer_backend" "ipv4" {
  for_each                 = var.enable_ipv4_backends ? local.ipv4_backend_registrations : {}
  backend_set_name         = oci_network_load_balancer_backend_set.ipv4[each.value.listener_name].name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  ip_address               = each.value.ip_address
  port                     = each.value.port
  weight                   = 1
}

resource "oci_network_load_balancer_backend" "ipv6" {
  for_each                 = var.enable_ipv6_backends ? local.ipv6_backend_registrations : {}
  backend_set_name         = oci_network_load_balancer_backend_set.ipv6[each.value.listener_name].name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  ip_address               = each.value.ip_address
  port                     = each.value.port
  weight                   = 1
}

resource "oci_network_load_balancer_listener" "ipv4" {
  for_each                 = local.ipv4_listener_keys
  default_backend_set_name = oci_network_load_balancer_backend_set.ipv4[each.key].name
  name                     = "${each.key}_ipv4"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  port                     = each.value.listener_port
  protocol                 = each.value.protocol
  ip_version               = "IPV4"
  tcp_idle_timeout         = 300
}

resource "oci_network_load_balancer_listener" "ipv6" {
  for_each                 = local.ipv6_listener_keys
  default_backend_set_name = oci_network_load_balancer_backend_set.ipv6[each.key].name
  name                     = "${each.key}_ipv6"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  port                     = each.value.listener_port
  protocol                 = each.value.protocol
  ip_version               = "IPV6"
  tcp_idle_timeout         = 300
}
