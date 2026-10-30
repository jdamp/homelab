# Kratzbaum

[Plant care tracker](https://github.com/jdamp/kratzbaum) at
[kratzbaum.mauzlab.de](https://kratzbaum.mauzlab.de). Argo CD sync is manual.

- **Authentication:** Authentik OIDC; `homelab-users` and `homelab-admins` share
  one collection. Manage the provider in `terraform/authentik/apps_kratzbaum.tf`;
  refresh credentials with `./create-oidc-sealed-secret.sh` from this directory.
  Preserve the OIDC issuer's trailing slash.
- **PlantNet:** `PLANTNET_API_KEY` uses Secret `kratzbaum-plantnet`, key `api-key`,
  managed by `plantnet-sealed-secrets.yaml`. After rotating the key, restart the
  deployment. Commit only encrypted credentials.
- **Storage:** SQLite and photos live in `/data` on a node-local PVC. Stop the
  deployment before backing up or restoring all of `/data`; restore ownership
  to UID/GID 10001. No automatic backups are configured.
