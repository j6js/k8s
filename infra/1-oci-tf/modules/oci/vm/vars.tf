variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID"
}
variable "tenancy_ocid" {
  type        = string
  description = "Tenancy OCID"
}

variable "subnet_id" {
  type        = string
  description = "Subnet OCID to attach the VM to"
}
variable "vcn_id" {
  type        = string
  description = "VCN OCID for NSG"
}
variable "local_ipv4_cidr" {
  type        = string
  description = "IPv4 CIDR for the local VCN"
}
variable "local_ipv6_cidr" {
  type        = string
  description = "IPv6 CIDR for the local VCN"
}
variable "peer_ipv4_cidrs" {
  type        = map(string)
  description = "Map of peer region name -> IPv4 VCN CIDR"
  default     = {}
}
variable "peer_ipv6_cidrs" {
  type        = map(string)
  description = "Map of peer region name -> IPv6 VCN CIDR"
  default     = {}
}
variable "image_id" {
  type        = string
  description = "Talos image OCID to use for all VMs"
}
variable "vms" {
  type = map(object({
    name   = string
    type   = string
    cpu    = number
    ram    = number
    disk   = number
    region = string
  }))
  description = "Map of VM configs keyed by name, from vms.yaml"
}
variable "firewall_rules" {
  type = list(object({
    name        = string
    description = string
    direction   = string
    protocol    = string
    ports       = list(number)
    source      = string
    destination = string
    role        = string
  }))
  description = "List of firewall rules"
  default     = []
}
variable "assign_public_ip" {
  type        = bool
  description = "Assign a public IP"
  default     = true
}
variable "shape" {
  type        = string
  description = "Instance shape"
  default     = "VM.Standard.A1.Flex"
}
variable "assign_ipv6ip" {
  type        = bool
  description = "Assign a public IPv6 IP"
  default     = true
}
