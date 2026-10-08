# Penpot

Penpot runs at **https://design.mauzlab.de** with Authentik login. Access is
limited to `homelab-users` and `homelab-admins`. Password login is disabled;
accounts are provisioned through OIDC.

The official Helm chart is pinned to `1.11.3` (Penpot `2.18.3`). It deploys
the frontend, backend, exporter, and official multi-user MCP server. A local
Valkey deployment handles transient notifications and MCP routing.

## MCP connection

1. Sign in, then open **Your account → Integrations → MCP Server**.
2. Enable MCP and generate a key. Copy the server URL shown there:
   `https://design.mauzlab.de/mcp/stream?userToken=YOUR_MCP_KEY`.
3. Add that URL to your client's remote MCP configuration. For example:

   ```json
   {
     "mcpServers": {
       "penpot": {
         "url": "https://design.mauzlab.de/mcp/stream?userToken=YOUR_MCP_KEY"
       }
     }
   }
   ```

4. Open a design file and use **File → MCP Server → Connect**. Keep the
   connected Penpot tab active while working with the client.
5. Start by asking the client to inspect the current page.

The frontend proxies both `/mcp/stream` and `/mcp/ws` through the same HTTPS
origin. The MCP service is internal; its official image runs in multi-user
mode and associates tool calls with the plugin connection's user token.
Without a connected design file, design operations return a connection error.
The key grants access to that connection; keep it out of Git and logs.

Upstream instructions: [Penpot MCP](https://help.penpot.app/mcp/).

## Storage and secrets

- Database: `penpot`, owned by the isolated `penpot` role on
  `postgres-shared-rw.databases.svc.cluster.local`. Covered by the shared
  cluster's existing Barman backups. Its connection pool is limited to 2–10
  connections to preserve capacity for the other apps.
- Assets: `penpot-data-assets`, a 20 GiB `ReadWriteMany` PVC on `nfs-nas`,
  shared by frontend and backend. Back up the NAS assets together with the DB.
- Credentials: `penpot-secrets`, created by `sealed-secrets.yaml`. Includes
  the persistent master key, database password, and Authentik client secret.
- OIDC: `https://auth.mauzlab.de/application/o/penpot/`, callback
  `https://design.mauzlab.de/api/auth/oidc/callback`. The backend explicitly
  allows `auth.mauzlab.de` through its SSRF protection because DNS resolves
  this trusted provider to a private address.
- SMTP is not configured. Login uses Authentik; invitation emails and email
  recovery require SMTP configuration if needed later.

## Deploy and restore

The apps ApplicationSet discovers this directory after it is pushed to Git.
Applications use manual Argo CD sync in this repository.

For initial provisioning, apply the Penpot Authentik resources in
`terraform/authentik/apps_penpot.tf`, then run from the repository root:

```sh
python3 kubernetes/apps/penpot/bootstrap.py
kustomize build --enable-helm kubernetes/apps/penpot > /tmp/penpot.yaml
kubectl create namespace penpot --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f /tmp/penpot.yaml
kubectl rollout status deployment -n penpot --timeout=300s
```

`bootstrap.py` creates the encrypted credentials and database without printing
plaintext secrets. Reruns reuse the live Secret and preserve existing roles and
databases. If the encrypted file exists but the live Secret does not, apply
`sealed-secrets.yaml` first and wait for unsealing before rerunning. Preserve
the original master key and database credentials when restoring.

Cloudflare's existing `*.mauzlab.de` record points to Traefik. The FritzBox
must allow `design.mauzlab.de` through DNS rebind protection. Traefik uses the
existing wildcard TLS certificate.

Check health with `curl -f https://design.mauzlab.de/readyz`. MCP transport
testing should include initialization, `tools/list`, and the `/mcp/ws`
WebSocket connection; a design operation additionally requires an active
Penpot plugin connection.
