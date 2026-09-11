# Paseo

Paseo provides a web UI and daemon for controlling the Codex and Pi coding
agents installed in `ghcr.io/jdamp/paseo-agents`. Argo CD discovers this
directory automatically and exposes the UI at <https://paseo.mauzlab.de>.

The deployment will not start without the `paseo-auth` Secret. Create it before
the first sync so the network-reachable daemon is never unauthenticated:

```sh
kubectl create namespace paseo --dry-run=client -o yaml | kubectl apply -f -
PASEO_PASSWORD="$(openssl rand -hex 32)"
printf 'Save this Paseo password: %s\n' "$PASEO_PASSWORD"
kubectl --namespace paseo create secret generic paseo-auth \
  --from-literal=password="$PASEO_PASSWORD"
unset PASEO_PASSWORD
```

For a fully GitOps-managed secret, seal it for this namespace instead:

```sh
PASEO_PASSWORD="$(openssl rand -hex 32)"
printf 'Save this Paseo password: %s\n' "$PASEO_PASSWORD"
kubectl --namespace paseo create secret generic paseo-auth \
  --from-literal=password="$PASEO_PASSWORD" --dry-run=client -o yaml | \
  kubeseal --controller-name sealed-secrets-controller \
    --controller-namespace sealed-secrets --format yaml \
    > kubernetes/apps/paseo/sealed-secrets.yaml
unset PASEO_PASSWORD
```

Add `sealed-secrets.yaml` to the resources in `kustomization.yaml` and commit
both files. The repository's ignore rules explicitly permit that filename.

## Provider and repository setup

`/home/paseo` persists Paseo state plus Codex, Pi, GitHub, and SSH credentials.
The shared coding area is the NFS-backed `/workspace` volume. The image starts
the daemon as the non-root `paseo` user, but `kubectl exec` starts commands as
the image's root bootstrap user, so use `gosu paseo` for interactive setup:

```sh
kubectl --namespace paseo exec -it deploy/paseo -- gosu paseo codex login --device-auth
kubectl --namespace paseo exec -it deploy/paseo -- gosu paseo pi
kubectl --namespace paseo exec -it deploy/paseo -- gosu paseo gh auth login
kubectl --namespace paseo exec -it deploy/paseo -- \
  gosu paseo git clone https://github.com/jdamp/homelab.git /workspace/homelab
```

Then open the Paseo UI, enter the password, and add `/workspace/homelab` as a
project. Provider API keys can alternatively be supplied through an additional
Kubernetes Secret and `secretKeyRef` environment variables.

The pod intentionally receives no Kubernetes service-account token. If agents
should operate on the cluster, mount a narrowly scoped kubeconfig or explicitly
grant this ServiceAccount only the RBAC permissions the agents need.
