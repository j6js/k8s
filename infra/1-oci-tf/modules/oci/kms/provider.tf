terraform {
  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = "8.12.0"
      configuration_aliases = [oci]
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.2.1"
    }
  }
}
