variable "compartment_ocid" {
  type        = string
  description = "The OCID of the compartment"
}

variable "tenancy_ocid" {
  type        = string
  description = "The tenancy OCID"
}

variable "region" {
  type        = string
  description = "The OCI region"
}

variable "service_user_name" {
  type        = string
  description = "The OCI IAM user name for CCM"
  default     = "ccm"
}

variable "service_group_name" {
  type        = string
  description = "The OCI IAM group name for CCM"
  default     = "ccm"
}

variable "admin_user_ocid" {
  type        = string
  description = "The OCID of the admin user to add to the CCM group"
}
variable "subnet_ocid" {
  type        = string
  description = "The OCID of the subnet"
}
variable "vcn_ocid" {
  type        = string
  description = "The OCID of the VCN"
}