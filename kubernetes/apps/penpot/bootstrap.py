#!/usr/bin/env python3
"""Seal Penpot credentials and create its isolated database on postgres-shared.

Run after applying the Penpot Authentik Terraform module. Requires kubectl,
kubeseal, terraform, and access to the current CNPG primary. Secrets stay in
memory; only the encrypted SealedSecret is written to disk.
"""

import base64
import json
import secrets
import subprocess
from pathlib import Path


APP = Path(__file__).resolve().parent
REPO = APP.parents[2]


def run(*args, stdin=None):
    result = subprocess.run(args, input=stdin, text=True, capture_output=True)
    if result.returncode:
        # Commands can include credentials in their error messages.
        raise SystemExit(f"{args[0]} failed (exit {result.returncode}); no credentials printed.")
    return result.stdout


def main():
    sealed_path = APP / "sealed-secrets.yaml"
    existing = run(
        "kubectl", "get", "secret", "penpot-secrets", "-n", "penpot",
        "--ignore-not-found", "-o", "json",
    )
    if existing.strip():
        data = {
            key: base64.b64decode(value).decode()
            for key, value in json.loads(existing)["data"].items()
        }
    else:
        if sealed_path.exists():
            raise SystemExit("Apply the existing SealedSecret and wait for penpot-secrets before rerunning; credentials will not be regenerated.")
        data = {
            "secret-key": secrets.token_urlsafe(64),
            "database-username": "penpot",
            "database-password": secrets.token_urlsafe(48),
            "oidc-client-id": "penpot",
            "oidc-client-secret": run(
                "terraform", f"-chdir={REPO / 'terraform/authentik'}",
                "output", "-raw", "penpot_oauth_client_secret",
            ).strip(),
        }

    secret = {
        "apiVersion": "v1", "kind": "Secret", "type": "Opaque",
        "metadata": {"name": "penpot-secrets", "namespace": "penpot"},
        "stringData": data,
    }
    sealed = run(
        "kubeseal", "--controller-name", "sealed-secrets-controller",
        "--controller-namespace", "sealed-secrets", "--format", "yaml",
        stdin=json.dumps(secret),
    )
    sealed_path.write_text(sealed)
    print("Encrypted credentials saved to", sealed_path)

    if data["database-username"] != "penpot":
        raise SystemExit("Unexpected database username.")
    password_literal = data["database-password"].replace("'", "''")
    primary = run(
        "kubectl", "get", "cluster", "postgres-shared", "-n", "databases",
        "-o", "jsonpath={.status.currentPrimary}",
    ).strip()
    # Existing roles are left unchanged. Reruns reuse the live Secret.
    sql = rf"""\set ON_ERROR_STOP on
SELECT format('CREATE ROLE penpot LOGIN PASSWORD %L', '{password_literal}')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'penpot') \gexec
SELECT 'CREATE DATABASE penpot OWNER penpot'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'penpot') \gexec
SELECT 1 / CASE WHEN pg_get_userbyid(datdba) = 'penpot' THEN 1 ELSE 0 END
FROM pg_database WHERE datname = 'penpot';
"""
    run(
        "kubectl", "exec", "-i", "-n", "databases", primary, "-c", "postgres",
        "--", "psql", "-U", "postgres", "-d", "postgres", stdin=sql,
    )
    print("Penpot database is ready on postgres-shared.")


if __name__ == "__main__":
    main()
