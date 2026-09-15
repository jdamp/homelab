# Klaus

Argo CD discovers this directory through the `homelab-apps` ApplicationSet and
creates the `klaus` namespace through its `CreateNamespace=true` sync option.
The application also grants Paseo namespace-scoped `edit` access for early
development.

## API-key SealedSecrets

`sealed-secrets.yaml` contains these Secrets:

| Secret | Key |
| --- | --- |
| `paseo-api-key` | `PASEO_API_KEY` |
| `telegram-bot-token` | `TELEGRAM_BOT_TOKEN` |

Do not create or commit a plaintext Secret manifest when rotating these values.
