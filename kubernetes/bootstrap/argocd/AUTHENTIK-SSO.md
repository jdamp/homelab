# Argo CD Authentik SSO

Run this manually after the normal Argo CD bootstrap. It is deliberately not
part of `kubernetes/bootstrap/argocd/kustomization.yaml`.

`homelab-admins` receives the Argo CD admin role; `homelab-users` is read-only.
Keep the local Argo CD `admin` account enabled until SSO has been tested.

```bash
terraform -chdir=terraform/authentik apply

kubectl create secret generic argocd-authentik \
  --namespace argocd \
  --from-literal=clientSecret="$(terraform -chdir=terraform/authentik output -raw argocd_oauth_client_secret)" \
  --dry-run=client -o yaml \
  | kubectl label --local --overwrite -f - app.kubernetes.io/part-of=argocd -o yaml \
  | kubeseal --namespace argocd --controller-namespace sealed-secrets --format yaml \
  | kubectl apply -f -

kubectl -n argocd patch configmap argocd-cm --type merge --patch-file /dev/stdin <<'EOF'
data:
  url: https://argocd.mauzlab.de
  dex.config: |
    connectors:
      - type: oidc
        id: authentik
        name: Authentik
        config:
          issuer: https://auth.mauzlab.de/application/o/argocd/
          clientID: argocd
          clientSecret: $argocd-authentik:clientSecret
          insecureEnableGroups: true
          scopes:
            - openid
            - profile
            - email
EOF

kubectl -n argocd patch configmap argocd-rbac-cm --type merge --patch-file /dev/stdin <<'EOF'
data:
  policy.csv: |
    g, homelab-admins, role:admin
    g, homelab-users, role:readonly
EOF
```

Verify with `argocd login argocd.mauzlab.de --sso`. Users must log in again
after their Authentik group membership changes.
