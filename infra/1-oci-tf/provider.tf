terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "8.16.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.4.1"
    }
  }
}
