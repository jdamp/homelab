---
name: update-homelab
description: Check, classify, plan, and perform approved software updates for jdamp's Kubernetes homelab, including application workloads, core platform apps, and Argo CD.
---

# Update the Kubernetes homelab

Use this repository's current checkout. Read its applicable instructions and current manifests first. Keep the skill and its supporting resources project-local; do not install a global user copy.

## Established user preferences

- Scope: `kubernetes/apps`, platform apps in `kubernetes/core`, and Argo CD in `kubernetes/bootstrap/argocd`. Include database/cache images, chart dependencies, init containers, and sidecars.
- Exclude K3s upgrades, VM/host packages, Proxmox, NAS/router firmware, Terraform provider upgrades, and local tooling upgrades unless explicitly requested. Inspect the Kubernetes version for compatibility without changing it. Updating the system-upgrade controller does not authorize changing its K3s Plans.
- Target latest stable releases. Present major upgrades separately; do not silently restrict discovery to the installed major. Treat calendar-version release trains and pre-1.0 compatibility changes according to upstream guidance.
- Downtime is acceptable for this homelab; no fixed maintenance window was requested. Core services matter more because applications depend on them. Validate dependencies and isolate core changes so a platform failure does not cascade into subsequent app updates.
- Do not infer missing consequential requirements. Research what the repository and cluster can answer, then ask concise questions about remaining gaps.
- Check updates, categorize and summarize, propose the exact updates and order, then obtain approval before performing updates. A request to check/update everything is not approval of an unseen wave plan.

## 1. Establish the baseline and discover updates

Check the Git working tree and preserve unrelated changes. Inspect every active ApplicationSet and the live Application list; READMEs may list retired apps. Compare Git pins with running pod images and image IDs, including workloads outside Argo CD's summaries.

The optional read-only helper prints candidate pin locations and a sanitized live summary:

```sh
python3 skills/update-homelab/scripts/collect.py --repo . --live
```

Its line scan is a starting point, not a chart renderer or complete dependency resolver. Resolve chart defaults, overrides, transitive images, remote manifests, and generated workloads separately. An image pin in Helm values can supersede the chart's appVersion.

Check nodes, application health/sync, active pod failures, database health, recent completed backups, and core networking/storage. Distinguish existing drift and old failed Backup CRs from new failures. A completed Backup CR is evidence of backup completion, not proof of a tested restore. Do not dump Secret contents or credentials into reports.

If the API is unreachable, try a bounded request (`kubectl --request-timeout=8s get --raw=/version`). This setup may require the user's VPN. Report the access problem and continue independent release research; never label Git pins as verified deployed versions.

Consult official release notes, security advisories, upgrade guides, chart indexes, and image registries as of the current date. Read every intervening release affecting the selected upgrade. Match each artifact's actual release stream: GitHub's `/releases/latest` or first release may select an older maintenance branch or an unrelated product. Compare stable version numbers within the correct stream, filtering RC/beta/dev and unrelated tags even if the prerelease flag is wrong. Paginate when the current pin or newer stable branches are absent.

For Helm, distinguish chart version from application versions. Inspect new and existing chart packages, dependencies, and rendered manifests. Use temporary Helm cache/config/data directories when necessary. For custom images such as `jdamp/kratzbaum` and `jdamp/paseo-agents`, check published registry tags and build provenance; no GitHub releases does not mean no updates. Rebuilding custom images is a separate proposed action if no suitable published artifact exists.

For floating tags or digest pins, compare registry manifests and runtime image IDs. A new digest can be a base-image rebuild with the same application version; classify it accordingly. Preserve image flavor, architecture, and coupled component versions. Verify that the actual registry/repository used by the deployment publishes the target (for example, Traefik's Rancher mirror).

## 2. Classify and present findings

Write a dated, concise report in the repository with one entry per app/component: running version, desired Git pin if different, latest stable candidate, classification, release-note link, migration/configuration effects, dependencies, downtime, verification, and recovery needs. Include current components and unresolved checks so coverage is explicit.

Classify by actual changes, not version-number size alone:

- Routine maintenance/security: no applicable breaking change or special migration found; normal restart and health checks.
- Coordinated update: chart/API/CRD changes, altered defaults, shared dependencies, data migrations, or recovery constraints require a component-specific procedure.
- Major/breaking: explicit upgrade-path and backup/restore review, separately presented for approval.
- Current or unresolved: state the evidence or precise remaining uncertainty.

Call out security priority separately from operational risk. Do not label a feature release or dependency rebuild as bugfix-only.

## 3. Make the plan concrete, then obtain approval

Prepare local candidate diffs and render affected charts/Kustomizations before asking for approval. Keep unapproved deployment candidates in a temporary checkout if useful. Specify exact targets, wave order, checks, backup actions, and which changes are deferred. Existing configuration drift that a sync would also apply must be described and included in approval or resolved without sweeping it into the update.

Prefer small waves: validate existing core dependencies; apply routine platform changes individually; apply independent app maintenance/security updates; handle coordinated and major upgrades separately. Adapt order to actual dependencies and security urgency. Do not make a dependency graph into a rigid rule that unnecessarily delays urgent independent fixes.

Do not push core changes before approval: this repository currently enables automatic sync, pruning, and self-heal for core applications. Apps currently require manual sync. Recheck live policies each run. Bootstrap Argo CD is outside those ApplicationSets and needs an explicit apply. Its Authentik SSO config is managed separately; preserve it when updating bootstrap resources.

Ask for approval of the concrete plan once it is reviewable. The approval requirement comes from the user's requested workflow. Do not ask again for actions already covered by that approval. If new findings materially change targets, migrations, data loss risk, or affected scope, stop the affected work and request revised approval.

## 4. Execute approved waves and verify

Carry out approved backup actions first. Check completed backups and application-specific persistent assets; PostgreSQL backups do not cover media libraries, uploaded documents, or SQLite PVCs. Preserve `Recreate`/single-writer behavior where configured. Never perform a PostgreSQL major upgrade by merely replacing an image tag.

Change the Git source of truth and publish/sync only the approved wave. A single push containing several core changes can start all of them simultaneously; use separate commits/pushes when sequencing matters. Wait for each critical platform component to recover before dependent changes. Avoid changing desired sync policy merely to perform maintenance.

Render Kustomize with Helm enabled where required; wrapper charts require dependency resolution. Use server-side validation when appropriate. Keep rendered Secrets out of tool output and reports. Check semantic changes to CRDs, RBAC, PVC identity, workload selectors, probes, services, and ingress—not only YAML syntax.

After each wave confirm rollout completion, expected runtime images/digests, Argo CD health/sync and resource ownership, database readiness/replication/archiving, core routing/storage, and relevant user-visible behavior (OIDC/login, uploads, playback, monitoring targets, etc.). Do not equate Synced with a working application.

Stop dependent updates on rollout failure, new platform/database degradation, migration errors, or failed recovery prerequisites. Diagnose and use the approved component-specific recovery path. Git/image rollback alone is not a safe reversal of an irreversible data migration; use the planned restore procedure when required. Do not blindly retry failed mutations or broaden a wave.

Record final versions, validation, deviations, deferred/unresolved items, and recovery actions in the report. Distinguish prepared Git edits, published commits, and verified live deployment; claim completion only for what was actually verified.
