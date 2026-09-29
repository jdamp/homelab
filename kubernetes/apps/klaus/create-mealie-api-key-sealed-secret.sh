#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
sealed_secrets_file="${script_dir}/sealed-secrets.yaml"

for command_name in kubectl kubeseal; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    printf 'Error: %s is required but was not found in PATH.\n' "${command_name}" >&2
    exit 1
  fi
done

if grep -Eq '^[[:space:]]+name:[[:space:]]+mealie-api-key[[:space:]]*$' "${sealed_secrets_file}"; then
  printf 'Error: mealie-api-key already exists in %s.\n' "${sealed_secrets_file}" >&2
  printf 'Remove its SealedSecret document before using this script to rotate the key.\n' >&2
  exit 1
fi

IFS= read -r -s -p 'Mealie API key: ' mealie_api_key
printf '\n'

if [[ -z "${mealie_api_key}" ]]; then
  printf 'Error: the Mealie API key cannot be empty.\n' >&2
  exit 1
fi

sealed_secret_file="$(mktemp)"
trap 'rm -f "${sealed_secret_file}"' EXIT

printf '%s' "${mealie_api_key}" \
  | kubectl --namespace klaus create secret generic mealie-api-key \
      --from-file=MEALIE_API_KEY=/dev/stdin \
      --dry-run=client -o yaml \
  | kubeseal \
      --controller-name sealed-secrets-controller \
      --controller-namespace sealed-secrets \
      --format yaml \
  > "${sealed_secret_file}"

unset mealie_api_key

if ! grep -q '^kind: SealedSecret$' "${sealed_secret_file}"; then
  printf 'Error: kubeseal did not produce a SealedSecret.\n' >&2
  exit 1
fi

printf '\n---\n' >> "${sealed_secrets_file}"
cat "${sealed_secret_file}" >> "${sealed_secrets_file}"

printf 'Added mealie-api-key (MEALIE_API_KEY) to %s for namespace klaus.\n' \
  "${sealed_secrets_file}"
