# Copyright Jackson Kelly 2026
# SPDX-License-Identifier: BUSL-1.1

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "8.15.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}
