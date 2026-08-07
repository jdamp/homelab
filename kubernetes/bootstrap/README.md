Install ArgoCD:

```bash
kubectl apply -k ./argocd
```

After the initial bootstrap, configure Authentik SSO manually by following
[`argocd/AUTHENTIK-SSO.md`](argocd/AUTHENTIK-SSO.md). It is intentionally kept
outside the Argo CD-managed `core/` and `apps/` ApplicationSets.
