resource "kubernetes_manifest" "ccm_service_account" {
    manifest = {
        apiVersion = "v1"
        kind = "ServiceAccount"
        metadata = {
            name = "cloud-controller-manager"
            namespace = "kube-system"
        }
    }
}
resource "kubernetes_manifest" "ccm_cluster_role_binding" {
    manifest = {
        apiVersion = "rbac.authorization.k8s.io/v1"
        kind = "ClusterRoleBinding"
        metadata = {
            name = "system:cloud-controller-manager"
        }
        subjects = [
            {
                kind = "ServiceAccount"
                name = kubernetes_manifest.ccm_service_account.manifest.metadata.name
                namespace = kubernetes_manifest.ccm_service_account.manifest.metadata.namespace
            }
        ]
        roleRef = {
            kind = "ClusterRole"
            name = kubernetes_manifest.ccm_rbac.manifest.metadata.name
            apiGroup = "rbac.authorization.k8s.io"
        }
    }
}
resource "kubernetes_manifest" "ccm_rbac" {
    # Sensitive because it's a large manifest and we don't want to log it in plaintext (and it doesn't contain any secrets btw)
    manifest = sensitive(yamldecode(
        <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: system:cloud-controller-manager
  labels:
    kubernetes.io/cluster-service: "true"
rules:
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - '*'

- apiGroups:
  - ""
  resources:
  - nodes/status
  verbs:
  - patch

- apiGroups:
  - ""
  resources:
  - services
  verbs:
  - list
  - watch
  - patch
  - get

- apiGroups:
  - ""
  resources:
  - services/status
  verbs:
  - patch
  - get
  - update

- apiGroups:
    - ""
  resources:
    - configmaps
  resourceNames:
    - "extension-apiserver-authentication"
  verbs:
    - get

- apiGroups:
  - ""
  resources:
  - events
  verbs:
  - list
  - watch
  - create
  - patch
  - update

# For leader election
- apiGroups:
  - ""
  resources:
  - endpoints
  verbs:
  - create

- apiGroups:
  - ""
  resources:
  - endpoints
  resourceNames:
  - "cloud-controller-manager"
  verbs:
  - get
  - list
  - watch
  - update

- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - create

- apiGroups:
    - "coordination.k8s.io"
  resources:
    - leases
  verbs:
    - get
    - create
    - update
    - delete
    - patch
    - watch

- apiGroups:
  - ""
  resources:
  - configmaps
  resourceNames:
  - "cloud-controller-manager"
  verbs:
  - get
  - update

- apiGroups:
    - ""
  resources:
    - configmaps
  resourceNames:
    - "extension-apiserver-authentication"
  verbs:
    - get
    - list
    - watch

- apiGroups:
  - ""
  resources:
  - serviceaccounts
  verbs:
  - create
  - list
  - get
  - watch
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
  - list

# For the PVL
- apiGroups:
  - ""
  resources:
  - persistentvolumes
  verbs:
  - list
  - watch
  - patch

  EOF
    ))
}