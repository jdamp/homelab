#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/../../.." && pwd)"

python3 - "${repo_root}" "${script_dir}" <<'PY'
import base64
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

repo_root, script_dir = map(Path, sys.argv[1:])
data = {}
for key, output in (
    ("client-id", "kratzbaum_oauth_client_id"),
    ("client-secret", "kratzbaum_oauth_client_secret"),
):
    value = subprocess.check_output(
        ["terraform", f"-chdir={repo_root / 'terraform/authentik'}", "output", "-raw", output]
    )
    if not value:
        raise SystemExit(f"Terraform output {output} is empty")
    data[key] = base64.b64encode(value).decode("ascii")

secret = {
    "apiVersion": "v1",
    "kind": "Secret",
    "metadata": {"name": "kratzbaum-oidc", "namespace": "kratzbaum"},
    "type": "Opaque",
    "data": data,
}
sealed = subprocess.run(
    ["kubeseal", "--controller-name", "sealed-secrets-controller",
     "--controller-namespace", "sealed-secrets", "--format", "yaml"],
    input=json.dumps(secret).encode(), stdout=subprocess.PIPE, check=True,
).stdout
if b"kind: SealedSecret" not in sealed:
    raise SystemExit("kubeseal did not produce a SealedSecret")

# Only ciphertext reaches disk; replace the existing file after sealing succeeds.
destination = script_dir / "oidc-sealed-secrets.yaml"
with tempfile.NamedTemporaryFile(dir=script_dir, delete=False) as temporary:
    temporary.write(sealed)
    temporary_path = Path(temporary.name)
try:
    temporary_path.chmod(0o644)
    os.replace(temporary_path, destination)
finally:
    temporary_path.unlink(missing_ok=True)
print(f"Updated {destination}")
PY
