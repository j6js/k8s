data "oci_objectstorage_namespace" "talos" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "talos_images" {
  compartment_id = var.compartment_ocid
  name           = "talos-images-${var.architecture}"
  namespace      = data.oci_objectstorage_namespace.talos.namespace
}

resource "oci_objectstorage_object" "talos_qcow2" {
  namespace    = data.oci_objectstorage_namespace.talos.namespace
  bucket       = oci_objectstorage_bucket.talos_images.name
  object       = "talos-${var.talos_version}-${var.architecture}.qcow2"
  source       = var.qcow2_source
  content_type = "application/octet-stream"
  content_md5  = filemd5(var.qcow2_source)
}

resource "oci_core_image" "talos" {
  compartment_id = var.compartment_ocid
  display_name   = "talos-${var.talos_version}-${var.architecture}"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type    = "objectStorageTuple"
    bucket_name    = oci_objectstorage_bucket.talos_images.name
    namespace_name = data.oci_objectstorage_namespace.talos.namespace
    object_name    = oci_objectstorage_object.talos_qcow2.object
  }
}

data "oci_core_compute_global_image_capability_schemas" "global" {}

locals {
  global_schema_id = data.oci_core_compute_global_image_capability_schemas.global.compute_global_image_capability_schemas[0].id
}

data "oci_core_compute_global_image_capability_schema" "global_current" {
  compute_global_image_capability_schema_id = local.global_schema_id
}

locals {
  global_schema_version_name = data.oci_core_compute_global_image_capability_schema.global_current.current_version_name
}

resource "oci_core_compute_image_capability_schema" "talos" {
  compartment_id                                      = var.compartment_ocid
  image_id                                            = oci_core_image.talos.id
  compute_global_image_capability_schema_version_name = local.global_schema_version_name
  display_name                                        = "talos-${var.architecture}-capability-schema"

  schema_data = {
    "Compute.Firmware" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "UEFI_64"
      values         = ["UEFI_64"]
    })

    "Storage.BootVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED"]
    })

    "Storage.RemoteDataVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED"]
    })

    "Network.AttachmentType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED"]
    })

    "Storage.LocalDataVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED"]
    })
  }
}

resource "oci_core_shape_management" "talos_shapes" {
  for_each = toset(var.shape_names)
  compartment_id = var.compartment_ocid
  image_id       = oci_core_image.talos.id
  shape_name     = each.value
}

output "image_id" {
  value = oci_core_image.talos.id
}
