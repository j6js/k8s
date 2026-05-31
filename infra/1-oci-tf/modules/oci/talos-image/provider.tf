terraform {
  required_providers {
    oci = {
      source                = "oracle/oci"
      version               = "8.16.0"
      configuration_aliases = [oci]
    }
  }
}