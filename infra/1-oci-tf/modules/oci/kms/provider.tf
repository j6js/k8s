# Copyright Jackson Kelly 2026
# SPDX-License-Identifier: BUSL-1.1

terraform {
  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = "8.16.0"
      configuration_aliases = [oci]
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.3.0"
    }
  }
}
