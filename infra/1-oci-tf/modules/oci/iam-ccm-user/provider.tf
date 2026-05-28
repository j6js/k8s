# Copyright Jackson Kelly 2026
# SPDX-License-Identifier: BUSL-1.1

terraform {
  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = "8.16.0"
      configuration_aliases = [oci]
    }
    time = {
      source  = "hashicorp/time"
      version = "0.14.0"
    }
  }
}
