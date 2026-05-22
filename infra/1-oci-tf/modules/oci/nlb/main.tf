data "oci_core_vcn" "this" {
  vcn_id = var.vcn_id
}

locals {
  active_backends = {
    for name, backend in var.backends : name => backend
    if contains(var.backend_roles, backend.role)
  }
  internet_cidrs = toset(["0.0.0.0/0", "::/0"])
  vcn_cidrs      = toset(concat(data.oci_core_vcn.this.cidr_blocks, data.oci_core_vcn.this.ipv6cidr_blocks))

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

resource "oci_core_network_security_group" "nlb" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "nsg-ingress-nlb-${var.region}"
}

resource "oci_core_network_security_group_security_rule" "nlb_ingress" {
  for_each = {
    for item in setproduct(keys(var.listeners), local.internet_cidrs) :
    "${item[0]}-${replace(item[1], "/", "_")}" => {
      listener = var.listeners[item[0]]
      cidr     = item[1]
    }
  }

  network_security_group_id = oci_core_network_security_group.nlb.id
  description               = "Allow public ingress to ${each.key}"
  direction                 = "INGRESS"
  protocol                  = "6"
  source_type               = "CIDR_BLOCK"
  source                    = each.value.cidr

  tcp_options {
    destination_port_range {
      min = each.value.listener.listener_port
      max = each.value.listener.listener_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "nlb_egress" {
  for_each = {
    for item in setproduct(keys(var.listeners), ["10.0.0.0/8"]) :
    "${item[0]}-${replace(item[1], "/", "_")}" => {
      listener = var.listeners[item[0]]
      cidr     = item[1]
    }
  }

  network_security_group_id = oci_core_network_security_group.nlb.id
  description               = "Allow NLB egress to ${each.key} backends"
  direction                 = "EGRESS"
  protocol                  = "6"
  destination_type          = "CIDR_BLOCK"
  destination               = each.value.cidr

  tcp_options {
    destination_port_range {
      min = each.value.listener.backend_port
      max = each.value.listener.backend_port
    }
  }
}

resource "oci_network_load_balancer_network_load_balancer" "ingress" {
  compartment_id             = var.compartment_id
  display_name               = "ingress-nlb-${var.region}"
  subnet_id                  = var.subnet_id
  nlb_ip_version             = "IPV4_AND_IPV6"
  is_private                 = false
  network_security_group_ids = [oci_core_network_security_group.nlb.id]
}

resource "oci_network_load_balancer_backend_set" "ipv4" {
  for_each                 = local.ipv4_listener_keys
  name                     = "${each.key}_ipv4"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  policy                   = "FIVE_TUPLE"
  ip_version               = "IPV4"
  is_preserve_source       = false

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
  is_preserve_source       = false

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
