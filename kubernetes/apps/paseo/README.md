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

`/home/paseo` persists Paseo state plus Codex, Pi, GitHub, and SSH credentials
on the 5 GiB `paseo-home` PVC (`local-path`, node-local storage). It survives pod
recreation but remains tied to the node that holds the volume; it is not stored
on or backed up automatically to the NAS. The shared coding area is `/workspace`,
on the separate 20 GiB `paseo-workspace` PVC (`nfs-nas`). The image starts
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

## Login-shell PATH

[profile.d/paseo-path.sh](profile.d/paseo-path.sh) is mounted read-only at
`/etc/profile.d/paseo-path.sh` through a generated ConfigMap. It restores
`/builder/bin`, `/usr/local/go/bin`, and `$HOME/go/bin` after the image's
`/etc/profile` resets `PATH`. This restores these tool paths for Codex's login
shells and shell snapshots. Pi's default non-login command runner
preserves the inherited environment and does not read this script.

Commit and push changes, then sync `paseo` in Argo CD. The ConfigMap name hash
triggers a pod recreation when the script changes. Start fresh Codex sessions
after syncing so they capture the updated shell environment.

## Shared global agent instructions

Edit [agent-instructions/AGENTS.md](agent-instructions/AGENTS.md) to manage the
defaults for both Codex and Pi across all Paseo projects. Kustomize generates
one ConfigMap from this file, and the deployment mounts its `AGENTS.md` key
read-only at both global instruction paths:

| Agent | Global instruction path |
| --- | --- |
| Codex | `/home/paseo/.codex/AGENTS.md` |
| Pi | `/home/paseo/.pi/agent/AGENTS.md` |

These are the default paths documented by
[Codex](https://learn.chatgpt.com/docs/agent-configuration/agents-md) and
[Pi](https://github.com/earendil-works/pi/blob/main/packages/coding-agent/docs/configuration.md).
Repository-level `AGENTS.md` files still provide project-specific guidance.
A global `AGENTS.override.md` can supersede the managed file; keep that in mind
if an agent reports unexpected instructions. If you customize `CODEX_HOME` or
`PI_CODING_AGENT_DIR`, update the corresponding mount path too.

Commit and push changes, then sync the `paseo` application in Argo CD. Automatic
sync is currently disabled in the apps ApplicationSet. Keep Kustomize's default
ConfigMap name hash enabled: changing the instructions changes the referenced
ConfigMap name and recreates the Paseo pod during sync. Expect a brief
interruption with the deployment's `Recreate` strategy. File mounts use
`subPath`, so updating only a ConfigMap in place would not refresh them.
Start a fresh agent session after syncing to load the new instructions.

Preview the manifests locally:

```sh
kubectl kustomize kubernetes/apps/paseo
```

After syncing, verify both files as the agent user:

```sh
kubectl --namespace paseo exec deploy/paseo -c paseo -- gosu paseo sh -ec '
  test -r /home/paseo/.codex/AGENTS.md
  test -r /home/paseo/.pi/agent/AGENTS.md
  cmp /home/paseo/.codex/AGENTS.md /home/paseo/.pi/agent/AGENTS.md
'
```

Use this repository and Argo CD for durable instruction changes. Ordinary
files edited directly under `/home/paseo` persist on the home PVC, but bypass
Git history and reproducible provisioning. The two managed instruction paths
are read-only mounts; edit the source file here instead. Keep secrets in the
existing credential storage, not in the instruction file or ConfigMap.

To inspect the current storage placement and underlying paths:

```sh
kubectl --namespace paseo get pvc paseo-home paseo-workspace -o wide
kubectl get pv "$(kubectl --namespace paseo get pvc paseo-home -o jsonpath='{.spec.volumeName}')" -o yaml
kubectl get pv "$(kubectl --namespace paseo get pvc paseo-workspace -o jsonpath='{.spec.volumeName}')" -o yaml
```

## Klaus development namespace

The Paseo ServiceAccount token is mounted for the workload. Its Kubernetes
resource permissions come from the Klaus Argo CD application's RoleBinding,
which grants the built-in `edit` role only in the `klaus` namespace. It can
create and update application resources there, but has no RoleBinding in the
`paseo` namespace and no cluster-wide role binding. The `edit` role does not
grant permission to manage RBAC.

Agents also have access to [development Postgres](../klaus/README.md#development-postgres)
in `klaus`.

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
