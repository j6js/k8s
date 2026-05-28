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
