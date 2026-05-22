# `3-k8s-infra` | 3. Kubernetes Infra

Step 3 in the infra deployment is to deploy everything needed to get the cluster into a state where ArgoCD is working and deployed. In this module, the following are created and/or set up:
  - [Cilium](https://cilium.io)
  - [ArgoCD](https://github.com/argoproj/argo-cd?tab=readme-ov-file#argo-cd---declarative-continuous-delivery-for-kubernetes)
  - [external-dns](https://kubernetes-sigs.github.io/external-dns/latest/)
  - And secrets required for:
    - ArgoCD
    - cert-manager (not installed by this step, but the DNS01 secret is set)
    - external-dns

This step requires Terraform, and SOPS (both of which are provided by the mise setup), plus the previous 2 steps need to have completed for any of this step to work.