terraform {
  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = "8.13.0"
      configuration_aliases = [oci]
    }
    time = {
      source  = "hashicorp/time"
      version = "0.14.0"
    }
  }
}
