locals {
    ccm_secrets = jsondecode(file("${path.module}/config/outputs/1-oci-tf.json")).ccm_secrets
}

resource "kubernetes_manifest" "ccm"{
    for_each = local.ccm_secrets
    manifest = yamldecode(templatefile("${path.module}/ccm.yaml.tftpl", {
        region = each.key
    }))
    depends_on = [kubernetes_secret_v1.ccm_secret]
}

resource "kubernetes_secret_v1" "ccm_secret" {
    for_each = local.ccm_secrets
    metadata {
        name      = "oci-ccm-${each.key}"
        namespace = "kube-system"
    }
    data = {
        "cloud-provider.yaml" = templatefile("${path.module}/ccm-secret.yaml.tftpl", {
            region = each.key,
            tenancy_ocid = sensitive(each.value.OCI_TENANCY_OCID)
            user_ocid = sensitive(each.value.OCI_USER_OCID)
            fingerprint = sensitive(each.value.OCI_FINGERPRINT)
            private_key = sensitive(each.value.OCI_PRIVATE_KEY)
            compartment_ocid = sensitive(each.value.OCI_COMPARTMENT_OCID)
            subnet_ocid = sensitive(each.value.OCI_SUBNET_OCID)
            vcn_ocid = sensitive(each.value.OCI_VCN_OCID)

        })
    }
}