# Copyright Jackson Kelly 2026
# SPDX-License-Identifier: BUSL-1.1

variable "compartment_ocid" {
  type        = string
  description = "The OCID of the compartment to create the policy in"
}

variable "region_name" {
  type        = string
  description = "The region name for the policy"
}

variable "group_ocid" {
  type        = string
  description = "The OCID of the group for CCM"
}