terraform {
  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = "8.18.0"
      configuration_aliases = [oci]
    }
  }
}