# Global agent instructions

- Always follow the OpenSpec workflow unless instructed otherwise
- Keep repositories and project files under `/workspace`; use `/home/paseo` for user configuration and persistent agent state.
- Build container images using `buildctl` which is mounted at `/builder/bin/buildctl`

## Development Postgres

- Shared disposable PostgreSQL is available at `postgres-dev-rw.paseo.svc.cluster.local:5432` (user `dev`, default database `dev`, no backups).
- Retrieve the connection URL using Paseo's Kubernetes access, then connect with `psql`:

  ```sh
  export DATABASE_URL="$(kubectl --namespace paseo get secret postgres-dev-app \
    -o jsonpath='{.data.fqdn-uri}' | base64 --decode)"
  psql "$DATABASE_URL"
  ```

- Use a separate database per project; the `dev` role can create databases. Update the URL's database name after creating one.
- Deployments in `paseo` can read the same Secret's `fqdn-uri` key via `secretKeyRef`. Other namespaces need their own credential Secret. Never print or commit the connection URL; it contains credentials.

