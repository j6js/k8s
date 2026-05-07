# OCI Cloud Controller Manager

OCI CCM lets Kubernetes `Service` resources with `type: LoadBalancer` create OCI load balancers and network load balancers.

This cluster is self-managed Talos, so Terraform still prepares two bits of cluster-specific input:

1. Talos node configuration gets `cloud-provider=external` and a per-node OCI instance provider ID.
2. `k8s/infra/oci-cloud-controller-manager/cloud-provider.secret.yaml` is generated from Terraform-owned OCI IDs.

For public Network Load Balancers, use service annotations like:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: public-gateway
  annotations:
    oci.oraclecloud.com/load-balancer-type: "nlb"
    oci.oraclecloud.com/security-rule-management-mode: "NSG"
    oci-network-load-balancer.oraclecloud.com/node-label-selector: oci-lb=j6js-public
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  ports:
    - name: http
      port: 80
      targetPort: 80
    - name: https
      port: 443
      targetPort: 443
```

Cilium Gateway API normally creates a `LoadBalancer` service for each Gateway, so put these annotations under `spec.infrastructure.annotations` on the Gateway.

