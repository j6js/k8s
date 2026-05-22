# `1-oci-tf` | 1. OCI Terraform

Step 1 is to deploy the initial infra required by this cluster, and handle multiple regions (linking them in a SD-LAN Full Mesh). In order, the following is created (non-exhaustive list):
  - VCN
  - Subnet / Acceptor RPCs
  - IAM Policies to allow Requestor RPCs to connect to Acceptors
  - Requestor RPCs
  - Talos Linux custom OS image
  - All VMs that will become nodes in the cluster.
  - Network Load Balancers that will be the ingress Load Balancers.
  - In the first region available, the OCI KMS Vault & Key are created to host HashiCorp Vault's Auto-Unseal feature.