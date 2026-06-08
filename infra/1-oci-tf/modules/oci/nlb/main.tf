
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
  listener_protocol_numbers = {
    for name, listener in var.listeners :
    name => listener.protocol == "UDP" || listener.protocol == "17" ? "17" : "6"
  }
  listener_protocol_names = {
    for name, listener in var.listeners :
    name => listener.protocol == "UDP" || listener.protocol == "17" ? "UDP" : "TCP"
  }
  listener_health_check_protocol_names = {
    for name, listener in var.listeners :
    name => listener.health_check_protocol == null ? local.listener_protocol_names[name] : listener.health_check_protocol
  }
  listener_health_check_ports = {
    for name, listener in var.listeners :
    name => listener.health_check_port == null ? listener.backend_port : listener.health_check_port
  }

  ipv4_backend_registrations = merge([
    for listener_name, listener in var.listeners : {
      for backend_name, backend in local.active_backends :
      "${listener_name}-${backend_name}" => {
        listener_name = listener_name
        backend_name  = backend_name
        port          = listener.backend_port
        target_id     = backend.private_ipv4_id
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
        target_id     = backend.ipv6_id
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
      listener_name = item[0]
      listener      = var.listeners[item[0]]
      cidr          = item[1]
    }
  }

  network_security_group_id = oci_core_network_security_group.nlb.id
  description               = "Allow public ingress to ${each.key}"
  direction                 = "INGRESS"
  protocol                  = local.listener_protocol_numbers[each.value.listener_name]
  source_type               = "CIDR_BLOCK"
  source                    = each.value.cidr

  dynamic "tcp_options" {
    for_each = strcontains(local.listener_protocol_names[each.value.listener_name], "TCP") ? [1] : []
    content {
      destination_port_range {
        min = each.value.listener.listener_port
        max = each.value.listener.listener_port
      }
    }
  }

  dynamic "udp_options" {
    for_each = strcontains(local.listener_protocol_names[each.value.listener_name], "UDP") ? [1] : []
    content {
      destination_port_range {
        min = each.value.listener.listener_port
        max = each.value.listener.listener_port
      }
    }
  }
}

resource "oci_core_network_security_group_security_rule" "nlb_egress_ipv4" {
  for_each = var.listeners

  network_security_group_id = oci_core_network_security_group.nlb.id
  description               = "Allow NLB egress to ${each.key} backends (IPv4)"
  direction                 = "EGRESS"
  protocol                  = local.listener_protocol_numbers[each.key]
  destination_type          = "CIDR_BLOCK"
  destination               = data.oci_core_vcn.this.cidr_blocks[0]

  dynamic "tcp_options" {
    for_each = strcontains(local.listener_protocol_names[each.key], "TCP") ? [1] : []
    content {
      destination_port_range {
        min = each.value.backend_port
        max = each.value.backend_port
      }
    }
  }

  dynamic "udp_options" {
    for_each = strcontains(local.listener_protocol_names[each.key], "UDP") ? [1] : []
    content {
      destination_port_range {
        min = each.value.backend_port
        max = each.value.backend_port
      }
    }
  }
}

resource "oci_core_network_security_group_security_rule" "nlb_egress_ipv6" {
  for_each = var.listeners

  network_security_group_id = oci_core_network_security_group.nlb.id
  description               = "Allow NLB egress to ${each.key} backends (IPv6)"
  direction                 = "EGRESS"
  protocol                  = local.listener_protocol_numbers[each.key]
  destination_type          = "CIDR_BLOCK"
  destination               = data.oci_core_vcn.this.ipv6cidr_blocks[0]

  dynamic "tcp_options" {
    for_each = strcontains(local.listener_protocol_names[each.key], "TCP") ? [1] : []
    content {
      destination_port_range {
        min = each.value.backend_port
        max = each.value.backend_port
      }
    }
  }

  dynamic "udp_options" {
    for_each = strcontains(local.listener_protocol_names[each.key], "UDP") ? [1] : []
    content {
      destination_port_range {
        min = each.value.backend_port
        max = each.value.backend_port
      }
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
  is_preserve_source       = true

  health_checker {
    protocol = "TCP" # would be a mess if we used UDP.
    port     = local.listener_health_check_ports[each.key]
    retries  = 3
  }
}

resource "oci_network_load_balancer_backend_set" "ipv6" {
  for_each                 = local.ipv6_listener_keys
  name                     = "${each.key}_ipv6"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  policy                   = "FIVE_TUPLE"
  ip_version               = "IPV6"
  is_preserve_source       = true

  health_checker {
    protocol = "TCP" # would be a mess if we used UDP.
    port     = local.listener_health_check_ports[each.key]
    retries  = 3
  }
}

resource "oci_network_load_balancer_backend" "ipv4" {
  for_each                 = var.enable_ipv4_backends ? local.ipv4_backend_registrations : {}
  backend_set_name         = oci_network_load_balancer_backend_set.ipv4[each.value.listener_name].name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  target_id                = each.value.target_id
  port                     = each.value.port
  name                     = "${each.value.backend_name}_${each.value.listener_name}_ipv4"
  weight                   = 1
}

resource "oci_network_load_balancer_backend" "ipv6" {
  for_each                 = var.enable_ipv6_backends ? local.ipv6_backend_registrations : {}
  backend_set_name         = oci_network_load_balancer_backend_set.ipv6[each.value.listener_name].name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  target_id                = each.value.target_id
  port                     = each.value.port
  name                     = "${each.value.backend_name}_${each.value.listener_name}_ipv6"
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
}

resource "oci_network_load_balancer_listener" "ipv6" {
  for_each                 = local.ipv6_listener_keys
  default_backend_set_name = oci_network_load_balancer_backend_set.ipv6[each.key].name
  name                     = "${each.key}_ipv6"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.ingress.id
  port                     = each.value.listener_port
  protocol                 = each.value.protocol
  ip_version               = "IPV6"
}
