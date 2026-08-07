# Argo CD Authentik SSO

Run this manually after the normal Argo CD bootstrap. It is deliberately not
part of `kubernetes/bootstrap/argocd/kustomization.yaml`.

`homelab-admins` receives the Argo CD admin role; `homelab-users` is read-only.
Keep the local Argo CD `admin` account enabled until SSO has been tested.

```bash
terraform -chdir=terraform/authentik apply

kubectl create secret generic argocd-authentik \
  --namespace argocd \
  --labels app.kubernetes.io/part-of=argocd \
  --from-literal=clientSecret="$(terraform -chdir=terraform/authentik output -raw argocd_oauth_client_secret)" \
  --dry-run=client -o yaml \
  | kubeseal --namespace argocd --controller-namespace sealed-secrets --format yaml \
  | kubectl apply -f -

kubectl -n argocd patch configmap argocd-cm --type merge --patch '{
  "data": {
    "url": "https://argocd.mauzlab.de",
    "dex.config": "connectors:\\n- type: oidc\\n  id: authentik\\n  name: Authentik\\n  config:\\n    issuer: https://auth.mauzlab.de/application/o/argocd/\\n    clientID: argocd\\n    clientSecret: $argocd-authentik:clientSecret\\n    insecureEnableGroups: true\\n    scopes:\\n    - openid\\n    - profile\\n    - email"
  }
}'

kubectl -n argocd patch configmap argocd-rbac-cm --type merge --patch '{
  "data": {
    "policy.csv": "g, homelab-admins, role:admin\\ng, homelab-users, role:readonly"
  }
}'
```

Verify with `argocd login argocd.mauzlab.de --sso`. Users must log in again
after their Authentik group membership changes.
