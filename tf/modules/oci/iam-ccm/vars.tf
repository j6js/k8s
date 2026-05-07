variable "tenancy_ocid" {
  type        = string
  description = "Tenancy OCID"
}

variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID containing the Kubernetes nodes and load balancers"
}

variable "region_name" {
  type        = string
  description = "OCI region name"
}

