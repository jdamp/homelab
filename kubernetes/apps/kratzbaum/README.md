# Kratzbaum

Self-hosted plant collection and care tracker from https://github.com/jdamp/kratzbaum.
Replaces the retired HortusFox deployment at https://kratzbaum.mauzlab.de.

The `homelab-apps` ApplicationSet discovers this directory and creates the
`kratzbaum` namespace. Automatic sync is currently disabled; sync the application
after publishing these manifests.

## Deployment

- Published image `0.1.6`, pinned by digest; upstream currently publishes amd64 only.
- One replica with `Recreate` updates to avoid concurrent SQLite writers.
- A 5 GiB `local-path` PVC stores the SQLite database and uploaded photos in `/data`.
- Runs as UID/GID 10001 with PVC group access, health probes, and Europe/Berlin time.
- Traefik serves HTTPS using the existing wildcard certificate.

Authentication uses Authentik OIDC and admits `homelab-users` and
`homelab-admins`. Everyone admitted shares the same plant collection.
`kratzbaum-oidc` supplies the client credentials through a SealedSecret.
The exact issuer is `https://auth.mauzlab.de/application/o/kratzbaum/`, including
its trailing slash. Image `0.1.6` fixes the issuer handling reported in
[kratzbaum#1](https://github.com/jdamp/kratzbaum/issues/1).

The provider and access policies are managed in
`terraform/authentik/apps_kratzbaum.tf`. After applying Terraform, refresh the
SealedSecret with `./kubernetes/apps/kratzbaum/create-oidc-sealed-secret.sh`.
The helper reads Terraform outputs and passes plaintext credentials to kubeseal
through a pipe without writing them to disk.

PlantNet identification is optional. To enable it, create a SealedSecret in the
`kratzbaum` namespace and reference its key as `PLANTNET_API_KEY` with
`valueFrom.secretKeyRef`. Do not commit the plaintext API key.

## Backup and restore

Stop the deployment before copying the entire `/data` directory, including
`kratzbaum.db` and `media/`. Restore both onto the PVC with UID/GID 10001 before
starting the deployment. The local-path volume is tied to its node; it has no
automatic database backup or replication.
