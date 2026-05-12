variable "compartment_id" {
  description = "The OCID of the compartment in which to create the network load balancer."
  type        = string
}
variable "region" {
  description = "The region in which to create the network load balancer."
  type        = string
}
variable "subnet_id" {
  description = "The OCID of the subnet in which to create the network load balancer."
  type        = string
}

variable "backends" {
  description = "Regional backend nodes keyed by node name."
  type = map(object({
    private_ipv4 = string
    public_ipv6  = string
    role         = string
  }))
}

variable "backend_roles" {
  description = "Node roles to register as NLB backends."
  type        = set(string)
  default     = ["cp", "sh", "wk"]
}

variable "listeners" {
  description = "Frontend listeners and Kubernetes NodePort backend ports."
  type = map(object({
    listener_port = number
    backend_port  = number
    protocol      = string
  }))
  default = {
    http = {
      listener_port = 80
      backend_port  = 30080
      protocol      = "TCP"
    }
    https = {
      listener_port = 443
      backend_port  = 30443
      protocol      = "TCP"
    }
  }
}

variable "enable_ipv4_backends" {
  description = "Create IPv4 backend sets, listeners, and backend registrations."
  type        = bool
  default     = true
}

variable "enable_ipv6_backends" {
  description = "Create IPv6 backend sets, listeners, and backend registrations."
  type        = bool
  default     = true
}
