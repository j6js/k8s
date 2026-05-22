variable "compartment_ocid" {
  type        = string
  description = "The OCID of the compartment where the vault will be created."
}

variable "user_ocid" {
  type        = string
  description = "The OCID of the user to be added to the Vault auto-unseal group."
}

variable "tenancy_ocid" {
  type        = string
  description = "The tenancy OCID where IAM resources for Vault auto-unseal will be created."
}

variable "region" {
  type        = string
  description = "The OCI region where the KMS vault and key will be created."
}

variable "service_user_name" {
  type        = string
  description = "The OCI IAM user name used by Vault for OCI KMS auto-unseal."
  default     = "vault-auto-unseal"
}

variable "service_group_name" {
  type        = string
  description = "The OCI IAM group name granted access to the Vault KMS key."
  default     = "vault-auto-unseal"
}
