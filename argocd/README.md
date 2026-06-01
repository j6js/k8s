# ArgoCD layout

The root Application points at this directory and renders child Applications from
`applications/`. Child Applications are grouped by lifecycle stage so bootstrap
ordering stays obvious as the cluster grows.

## Application directories

- `00-platform-crds/`: controllers and charts that provide CRDs or foundational APIs.
- `10-platform-services/`: platform services that depend on those APIs.
- `20-platform-config/`: reusable cluster config such as issuers, secret stores, and gateway classes.
- `30-workloads/`: workload Applications and workload-specific config.
- `40-routing/`: shared Gateway, certificates, DNS records, routes, and edge policies.

## Sync waves

- `-20`: CRD and platform API providers.
- `-10`: platform services that need the API providers.
- `0`: shared platform config.
- `10`: workloads and workload config.
- `20`: routing and exposure.

Prefer the earliest wave where all CRDs, namespaces, secrets, and referenced
controllers already exist. If a chart both provides CRDs and has workloads that
depend on later config, keep the CRD provider early and document any health-check
exception on that Application.

## Adding an app

Put the Application spec in the lifecycle directory matching what it creates,
then choose the wave from the dependency it consumes, not from the app name. Keep
CR-consuming manifests after the Application that installs their CRDs, and keep
`ExternalSecret` resources after `ClusterSecretStore` is available.

## Security hardening notes

Namespace Pod Security Admission should usually start at `enforce: baseline`
with `audit` and `warn` set to `restricted`. Move a namespace to restricted
enforcement only after the audit events are clean. Longhorn, Vault, and the
observability stack are currently known exceptions because they use host access,
privileged storage behavior, or locking capabilities.

Argo CD can verify Git source integrity with trusted GPG keys, but image
signature and SLSA provenance enforcement belongs at admission time. Prefer
Kyverno `verifyImages` or Sigstore policy-controller for Cosign/SLSA checks,
starting in audit/warn mode before enforcing.

Docker Hardened Images should be trialed per workload rather than applied
globally. Distroless/no-shell images are useful, but chart probes, init
containers, writable paths, expected UIDs, and debug workflows need compatibility
checks before switching production workloads.

## Authentik SSO

Argo CD is configured to use Authentik through Dex so browser and CLI login both
work. Create an Authentik OAuth2/OpenID Connect application/provider with client
ID `argocd`, provider slug `argocd`, strict redirect URI
`https://argo.j6js.com/api/dex/callback`, and strict redirect URI
`https://localhost:8085/auth/callback`.

Create Authentik groups named `ArgoCD Admins` and `ArgoCD Viewers`; Argo CD maps
them to `role:admin` and `role:readonly`.

Store the provider client secret in `infra/.sops/argocd.yaml` as
`oidcAuthentikClientSecret`. Terraform will put it in `argocd-secret` as
`dex.authentik.clientSecret` during the Argo CD Helm release.
