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

## Klaus development namespace

The Paseo pod receives its `paseo` ServiceAccount token so agents can work in
the `klaus` development namespace. The Klaus Argo CD application binds the
namespace-scoped built-in `edit` role to this ServiceAccount. This supports
creating and updating Deployments and other application resources without
granting cluster-wide access or permission to manage RBAC.

The ServiceAccount itself retains `automountServiceAccountToken: false` as its
default. Only the Paseo Deployment explicitly opts into token mounting, so an
unrelated pod cannot gain this access merely by selecting the ServiceAccount.

## Container builds

Paseo includes a rootless BuildKit sidecar. The `buildctl` client is available
on the agent's `PATH` and uses the sidecar automatically through
`BUILDKIT_HOST`. Dockerfile builds can use the normal BuildKit Dockerfile
frontend, for example:

```sh
buildctl build \
  --frontend dockerfile.v0 \
  --local context=/workspace/homelab \
  --local dockerfile=/workspace/homelab \
  --output type=oci,dest=/workspace/homelab/image.tar
```

The builder is isolated to the pod and does not expose the Kubernetes node's
container runtime. Its cache is ephemeral and is rebuilt when the pod is
recreated.

The builder runs as UID/GID 1000 but allows privilege escalation for
RootlessKit's `newuidmap`/`newgidmap` helpers. Its seccomp and AppArmor profiles
are unconfined to permit rootless namespace and mount operations.
`--oci-worker-no-process-sandbox` permits Dockerfile `RUN` steps with
Kubernetes' masked `/proc`, but build processes share the builder's PID
namespace and can signal builder processes or survive a build step. Only
build trusted Dockerfiles. These exceptions apply to the BuildKit sidecar;
Paseo retains `allowPrivilegeEscalation: false` and its default seccomp profile.
