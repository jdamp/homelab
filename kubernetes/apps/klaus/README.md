# Klaus

Argo CD discovers this directory through the `homelab-apps` ApplicationSet and
creates the `klaus` namespace through its `CreateNamespace=true` sync option.
The application also grants Paseo namespace-scoped `edit` access for early
development.

## Development Postgres

`postgres-dev` runs PostgreSQL 18 via CloudNativePG: one instance, 2 GiB local
storage, 100m CPU / 256 MiB RAM requested. No backups or replicas; data is
disposable. The shared `dev` user can create a database per project.

Inside a Paseo agent shell:

```sh
export DATABASE_URL="$(kubectl --namespace klaus get secret postgres-dev-app \
  -o jsonpath='{.data.fqdn-uri}' | base64 --decode)"
```

This connects to the `dev` database at
`postgres-dev-rw.klaus.svc.cluster.local:5432`. Deployments in `klaus` can use
the same Secret's `fqdn-uri` key via `secretKeyRef`.

## API-key SealedSecrets

`sealed-secrets.yaml` is used to manage these Secrets:

| Secret | Key |
| --- | --- |
| `kaneo-api-key` | `KANEO_API_KEY` |
| `mealie-api-key` | `MEALIE_API_KEY` |
| `telegram-bot-token` | `TELEGRAM_BOT_TOKEN` |

Do not create or commit a plaintext Secret manifest when rotating these values.

To add the Mealie API key, run the helper and enter the token at its hidden
prompt:

```sh
./kubernetes/apps/klaus/create-mealie-api-key-sealed-secret.sh
```

The helper passes the token to `kubectl` over standard input, seals it for the
`mealie-api-key` Secret in the `klaus` namespace, and appends the result to the
tracked `sealed-secrets.yaml`. It never writes the plaintext token to disk.

`mealie-config` provides the non-sensitive `MEALIE_BASE_URL` value. A
Deployment can consume both settings with `envFrom`:

```yaml
envFrom:
  - configMapRef:
      name: mealie-config
  - secretRef:
      name: mealie-api-key
```
