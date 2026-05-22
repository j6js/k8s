variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID to store the image in"
}
variable "talos_version" {
  type        = string
  description = "Talos version to deploy (e.g. v1.13.0)"
  default     = "v1.13.0"
}
variable "architecture" {
  type        = string
  description = "CPU architecture: arm64 or amd64"
  default     = "arm64"
}
variable "qcow2_source" {
  type        = string
  description = "Local path to the qcow2 file to upload"
  default     = "talos/oracle-arm64.qcow2"
}
variable "shape_names" {
  type        = list(string)
  description = "List of OCI shapes to enable for this image"
  default     = ["VM.Standard.A1.Flex"]
}