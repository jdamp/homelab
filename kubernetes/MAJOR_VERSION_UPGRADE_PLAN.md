# Major Version Upgrade Plan

This document tracks the major-version upgrades for the homelab Kubernetes
workloads. It is a runbook only: do not combine these changes with routine
image updates, and make one independently reversible change per maintenance
window.

## Scope

| Component | Baseline | Target | Status | Manifest |
| --- | --- | --- | --- | --- |
| Homepage | `v1.13.2` | `v2.0.0` | Migrated 2026-08-27 (`0917171`) | `apps/homepage/deployment.yaml` |
| Paperless-ngx | `2.20.15` | `3.0.5` | Migrated 2026-08-27 (`aa7755c`) | `apps/paperless-ngx/paperless/deployment.yaml` |
| Immich application and machine learning | `v2.7.5` | `v3.1.0` | Deployed 2026-09-03 (`610786f`); manual acceptance pending | `apps/immich/immich-values.yaml` |
| Immich VectorChord/PostgreSQL | `16.9-0.4.3` | `17.10-1.1.1` | Migrated 2026-08-28 | `apps/immich/postgres/cluster.yaml` |

Immich already uses VectorChord, not pgvecto.rs. This satisfies the Immich v3
requirement to move away from pgvecto.rs.

## Progress snapshot (2026-09-03)

- Homepage and Paperless-ngx are deployed at their targets. Argo CD reports
  both applications `Synced` and `Healthy` at revision `aa7755c`.
- Production Immich is deployed at application and machine learning `v3.1.0`.
  Its database is healthy on PostgreSQL `17.10`, VectorChord `1.1.1`, and
  pgvector `0.8.2`. Argo CD is `Synced` and `Healthy` at revision
  `610786fd9a4a92e9069fa1a50a46af46e3b4bbe9`.
- The final quiesced PostgreSQL 16 backup is `20260828T151130`. The first
  PostgreSQL 17 base backup is `20260828T151442`; WAL and backups use the
  separate `postgres-cluster-pg17` archive. Retain both backup lineages.
- The live PostgreSQL 17 amd64 image digest is
  `sha256:f22538c11c6d0e9ade44d3224f2dccd6bad9b2e60034b2e118804f9ad35f59bf`.
- Scheduled PostgreSQL 17 backup `20260830T030000` was restored successfully
  into `immich-v3-rehearsal/postgres-v3-rehearsal` for the application
  rehearsal. Final quiesced pre-v3 backup `20260903T062115` is `DONE` in the
  `postgres-cluster-pg17` archive.
- Immich v3.1.0 passed the isolated rehearsal and automated production checks.
  Retain the rehearsal, backup, and prior manifest commit until authenticated
  browser/mobile, upload, sharing, and integrity-report checks pass and the
  application completes at least one full backup cycle.

## Global preflight gate

Complete and record all of the following before changing a production
manifest:

1. Create a dedicated Git commit for one component only. Do not batch these
   upgrades.
2. Schedule a maintenance window and disable incoming writes where noted.
3. Record the current image digests, Argo CD revision, health, and a baseline
   smoke test for the affected application.
4. Verify available storage capacity for a parallel database restore and for
   backup retention.
5. Create a fresh backup and perform a restore test in an isolated namespace.
   A backup that has not been restored successfully is not a rollback plan.
6. Define a go/no-go decision point before every irreversible database
   migration.

## Recommended order

1. Homepage v2 — migrated
2. Paperless-ngx v3 — migrated
3. Immich VectorChord/PostgreSQL 17 — migrated
4. Immich v3 — deployed; manual acceptance pending

This keeps the two database-changing operations separate and moves the
Immich application only after its target database has been accepted.

## 1. Homepage v1 to v2

### Risks and preflight

- Homepage v2 introduces built-in authentication. Decide whether it should be
  enabled; retain the existing reverse-proxy protections if it is not.
- Preserve `HOMEPAGE_ALLOWED_HOSTS=home.mauzlab.de` and verify the configured
  host is still accepted.
- Review every configured service widget, Docker integration, Kubernetes
  integration, bookmark, and external API before the production change.

### Procedure

1. Deploy `v2.0.0` in a temporary namespace with a copy of the ConfigMap and
   read-only Kubernetes credentials.
2. Verify page rendering, widget API calls, bookmarks, and host validation.
3. Update the production image tag in `apps/homepage/deployment.yaml`.
4. Verify the readiness endpoint, browser access through Traefik, and all
   widgets after Argo CD reports healthy.

### Rollback

Revert the image tag to `v1.13.2`. Homepage has no application database in
this deployment, so the rollback is limited to the image and configuration.

References: [Homepage v2 release notes](https://github.com/gethomepage/homepage/releases/tag/v2.0.0) and [Homepage installation guide](https://gethomepage.dev/installation/).

## 2. Paperless-ngx v2 to v3

### Risks and preflight

- v3 changes the search backend from Whoosh to Tantivy and includes database
  migrations.
- Review any pre- or post-consume scripts, API clients, document/thumbnail
  encryption, and advanced database settings. v3 removes positional script
  arguments and API versions below v9.
- Back up the PostgreSQL database as well as the `data`, `media`, `consume`,
  and `export` storage. The deployment mounts data locally and the latter
  three paths on persistent storage.
- Rehearse the upgrade from restored data in an isolated namespace. Verify
  migrations, search index creation, OCR, ingestion, OIDC login, exports, and
  document retrieval.

### Procedure

1. Pause ingestion and ensure the consume directory is empty or accounted for.
2. Take a final verified backup.
3. Change only the Paperless image to the selected v3 release.
4. Watch the application logs until migrations and search-index setup finish.
5. Re-enable ingestion and smoke-test OIDC, a document upload, OCR, search,
   download, and export.

### Rollback

Do not rely on an image-only downgrade after migrations. Restore the database
and persistent data from the verified pre-upgrade backup, then restore the v2
manifest.

Reference: [Paperless-ngx v3.0.0 release notes](https://github.com/paperless-ngx/paperless-ngx/releases/tag/v3.0.0).

## 3. Immich VectorChord/PostgreSQL 16 to 17

### Risks and preflight

- This is an offline PostgreSQL major-version upgrade with custom extensions.
- The current database is a single-instance CloudNativePG cluster using
  `cloudnative-vectorchord:16.9-0.4.3`, `vchord`, and `earthdistance`.
- It has weekly Barman backups. Trigger a fresh backup and restore it before
  proceeding; do not rely only on the scheduled backup.
- Use `cloudnative-vectorchord:17.10-1.1.1` as the final target. The major
  upgrade must first use `cloudnative-vectorchord:17.5-0.4.3` so `pg_upgrade`
  has the same VectorChord version on both sides. PostgreSQL 17.5 has a known
  replication-slot upgrade bug, but the current cluster and successful
  rehearsal both have `max_slot_wal_keep_size=-1`, which is CloudNativePG's
  documented workaround.
- Confirm that the source and target images use the same operating-system
  distribution, as required by CloudNativePG's in-place upgrade, and test the
  complete VectorChord extension upgrade path from `0.4.3` to `1.1.1`.
- Give the PostgreSQL 17 backup archive a distinct Barman `serverName` so its
  new timeline does not collide with the retained PostgreSQL 16 archive.

### Procedure

1. Trigger a fresh PostgreSQL 16 backup and restore it into a temporary
   CloudNativePG cluster using the same
   `cloudnative-vectorchord:16.9-0.4.3` source image. A physical Barman backup
   cannot be restored directly into a different PostgreSQL major version.
2. Stop Immich writes for the entire production operation and take and verify
   a final PostgreSQL 16 backup.
3. Change the database image to
   `cloudnative-vectorchord:17.5-0.4.3`. Change the Barman plugin `serverName`
   to `postgres-cluster-pg17` in the same commit so the PostgreSQL 17 timeline
   cannot collide with the retained PostgreSQL 16 archive.
4. Wait for the offline `pg_upgrade` job and PostgreSQL 17.5 cluster to become
   healthy. Verify row counts and that `vchord` remains at `0.4.3` before
   proceeding. This is the irreversible go/no-go point; after a successful
   major upgrade, restoring the PostgreSQL 16 backup is the downgrade path.
5. Change the image to `cloudnative-vectorchord:17.10-1.1.1`. After the pod is
   healthy, verify the extension paths and run in one transaction:

   ```sql
   ALTER EXTENSION vector UPDATE TO '0.8.2';
   ALTER EXTENSION vchord UPDATE TO '1.1.1';
   ```

6. Rebuild the VectorChord indexes because the `0.4.3` index format is not
   readable by `1.1.1`, then refresh optimizer statistics:

   ```sql
   REINDEX (VERBOSE) INDEX public.face_index;
   REINDEX (VERBOSE) INDEX public.clip_index;
   ANALYZE;
   ```

7. Validate PostgreSQL 17.10, all extension versions, row counts, schema dump,
   and indexed smart-search and face-search queries with
   `SET LOCAL vchordrq.probes = 1`, matching Immich's search SQL. Re-enable
   Immich only after these checks pass.
8. Take a new PostgreSQL 17 base backup immediately. Pre-upgrade backups and
   WAL cannot provide point-in-time recovery across the major-version
   boundary.

### Rehearsal result (2026-08-28)

- Restored backup `20260828T145522` into the isolated
  `immich-pg17-rehearsal/postgres-rehearsal` cluster using PostgreSQL 16.9 and
  VectorChord 0.4.3. The production and restore schema hashes matched, as did
  key counts: 32,507 assets, 37 albums, 2,227 people, one user, and 32,482 EXIF
  rows.
- A direct upgrade from `16.9-0.4.3` to `17.10-1.1.1` failed safely during
  schema restore because the 1.1.1 library no longer exports a function needed
  by the 0.4.3 schema. Reverting the image restarted the unchanged PostgreSQL
  16 data successfully.
- The corrected `16.9-0.4.3` to `17.5-0.4.3` `pg_upgrade` completed in 37
  seconds. The subsequent roll to `17.10-1.1.1` completed in 14 seconds.
- Updating pgvector to 0.8.2 and VectorChord to 1.1.1 succeeded. Rebuilding
  `face_index` (135 MB before rebuild) and `clip_index` (93 MB before rebuild)
  took eight seconds total. `ANALYZE` then completed successfully.
- The final cluster is healthy with no pod restarts. Key row counts remain
  unchanged, and `clip_index` and `face_index` both served indexed similarity
  queries using the probe setting from Immich v2.7.5.

### Production result (2026-08-28)

- Immich writes were stopped and PostgreSQL reported no application sessions.
  Final PostgreSQL 16 backup `20260828T151130` completed before the upgrade.
- The PostgreSQL 16.9 to 17.5 `pg_upgrade` completed in 39 seconds. PostgreSQL
  17.5 passed the intermediate health, extension, and row-count gate.
- The roll to PostgreSQL 17.10 completed in 13 seconds. Updating pgvector to
  0.8.2 and VectorChord to 1.1.1, rebuilding `face_index` and `clip_index`, and
  running `ANALYZE` completed successfully.
- The final database retained 32,507 assets, 37 albums, 2,227 people, one user,
  and 32,482 EXIF rows. Both VectorChord indexes served representative Immich
  queries, the schema dump completed, and the database pod had zero restarts.
- PostgreSQL 17 base backup `20260828T151442` completed successfully in the new
  `postgres-cluster-pg17` archive. Continuous WAL archiving is healthy. A
  direct `barman-cloud-backup-list` check reported both this backup and the
  final PostgreSQL 16 backup `20260828T151130` as `DONE` in their respective
  archive lineages.
- Immich v2.7.5 and machine learning resumed with ready pods and zero restarts.
  The public ping returned `pong`, and the version endpoint returned `2.7.5`.

### Rollback

For a failed in-place upgrade, restore the PostgreSQL 16 image reference; the
operator removes the failed upgrade job and restarts the unchanged source data.
If the upgrade completed and writes resumed, stop the application and restore
the verified PostgreSQL 16 backup rather than attempting a downgrade. For a
blue/green cutover, point Immich back to the retained PostgreSQL 16 cluster
only if no writes occurred on PostgreSQL 17.

References: [CloudNativePG PostgreSQL upgrades](https://cloudnative-pg.io/docs/1.30/postgres_upgrades/), [VectorChord image matrix](https://github.com/tensorchord/cloudnative-vectorchord/blob/main/versions.yaml), and [Immich upgrade guidance](https://docs.immich.app/install/upgrading/).

## 4. Immich v2 to v3

### Risks and preflight

- Upgrade mobile clients first. Immich recommends matching the server to the
  current mobile major version.
- Audit API consumers: third-party scripts, Homepage widgets, shared-link
  clients, and automations must not use removed or changed v2 endpoints.
- Confirm no removed machine-learning environment variables are configured.
- Confirm every x86 node meets the x86-64-v2 baseline required by v3 machine
  learning dependencies.
- Reconfirm the Immich database backup/restore result immediately before the
  production application change.

### Procedure

1. Confirm all mobile clients are v3 compatible and recheck any API consumers
   that are maintained outside this repository.
2. During the maintenance window, stop Immich writes and confirm PostgreSQL
   has no application sessions. Take a final PostgreSQL 17 backup and verify
   that Barman reports it as `DONE` in the `postgres-cluster-pg17` archive.
3. Make the irreversible go/no-go decision only after that backup is verified.
   Push the dedicated `v3.1.0` application manifest commit after approval.
4. Let Argo CD roll the server and machine-learning workloads, then watch for
   completed migrations, no schema drift, storage-integrity checks, and job
   failures.
5. Validate OIDC, web and mobile login, uploads, search, machine learning,
   background jobs, sharing, API automation, and the new integrity report.
6. Re-run metadata extraction if the new v3 video-processing features are to
   be used on assets imported before v3.

### Rehearsal result (2026-08-31)

- Restored scheduled PostgreSQL 17 backup `20260830T030000` into the new,
  isolated `immich-v3-rehearsal/postgres-v3-rehearsal` cluster. PostgreSQL
  17.10, VectorChord 1.1.1, pgvector 0.8.2, and earthdistance 1.2 were healthy.
  Baseline counts matched production: 32,507 assets, 37 albums, 2,227 people,
  one user, and 32,482 EXIF rows.
- Deployed chart 0.13.1 with Immich server and machine learning `v3.1.0`, no
  ingress, isolated Valkey, and scratch library/cache volumes. Migrations
  completed, the schema-drift check passed, and the version history recorded
  3.1.0. The first server process then stopped because the intentionally empty
  scratch library lacked `.immich` integrity markers. After initializing the
  empty volume like a fresh installation, the replacement pod started cleanly.
  Post-migration record counts remained unchanged.
- The server and machine-learning pods became ready with zero restarts. The
  ping endpoint returned `pong`, the version endpoint returned `3.1.0`, the
  machine-learning ping returned `pong`, and OAuth remained enabled with the
  Authentik button configuration. The target server and machine-learning image
  IDs were respectively
  `sha256:b434cb9287eea1471c9974845914d4dd328c9c2d652e446ed4930f99944f0ceb`
  and
  `sha256:5a0839dc5303cd7215bcd2180a26aed3af41675aefb3e75e5157e9f10ad16e6e`.
- Both `clip_index` and `face_index` served representative indexed similarity
  queries. Smart-search returned five rows in 60 ms and face-search returned
  five rows in 21 ms in the isolated cluster.
- The v3.1.0 machine-learning image started successfully on both schedulable
  amd64 workers, satisfying the x86-64-v2 runtime gate. The manifest contains
  none of the removed user-configured machine-learning environment variables.
- The repository API-consumer audit found only a normal Homepage link to
  Immich and no Immich API widget or automation. External consumers still
  require confirmation at the production go/no-go.
- Because the rehearsal intentionally used a scratch media volume and no
  ingress, real-library reads, upload processing, browser/mobile OIDC, sharing,
  and the integrity report remain production-window acceptance tests. Retain
  the rehearsal namespace through production acceptance.

### Production result (2026-09-03)

- Scaled the server and machine-learning deployments to zero and confirmed
  PostgreSQL had no remaining Immich sessions. The final pre-migration counts
  were 32,507 assets, 37 albums, 2,227 people, one user, and 32,482 EXIF rows.
- Backup resource `immich-v3-preupgrade-20260903` completed as Barman backup
  `20260903T062115`, covering WAL `000000010000003600000029`. A direct object
  store catalog check reported the backup as `DONE` in the
  `postgres-cluster-pg17` archive.
- Pushed dedicated application commit `610786f` and manually synced that exact
  revision through Argo CD with pruning disabled. Database migrations finished
  in approximately two seconds, the production storage-integrity checks
  passed, and the version history recorded 3.1.0.
- One API worker reported schema drift during the initial two-worker migration
  race while the microservices worker reported no drift. The explicit
  `immich-admin schema-check` immediately reported current migrations and no
  drift. A controlled server-pod replacement then produced clean no-drift
  results from both workers.
- Argo CD is `Synced` and `Healthy`. Server, machine learning, and Valkey are
  ready with zero restarts. The v3 server and machine-learning image IDs are
  respectively
  `sha256:b434cb9287eea1471c9974845914d4dd328c9c2d652e446ed4930f99944f0ceb`
  and
  `sha256:5a0839dc5303cd7215bcd2180a26aed3af41675aefb3e75e5157e9f10ad16e6e`.
- Both internal and public HTTPS ping/version checks returned `pong` and
  `3.1.0`; the public web route returned HTTP 200. Immich generated a valid
  Authentik authorization redirect, OAuth remained enabled, and the
  machine-learning service returned `pong`.
- The production media mount contains readable data and all six Immich mount
  markers passed. Post-migration counts remained unchanged. PostgreSQL retained
  earthdistance 1.2, VectorChord 1.1.1, and pgvector 0.8.2. `clip_index` and
  `face_index` served representative indexed searches in approximately 10 ms,
  and the new `integrity_report` table exists.
- Authenticated browser/mobile OIDC, upload and OCR processing, document/media
  download, background-job completion, sharing, API automation, and generation
  of an integrity report require manual user acceptance before closing the
  maintenance item.

### Rollback

Immich does not support database downgrades. If the v3 schema migration cannot
be accepted, restore the verified database backup and v2 manifests; do not
attempt a tag-only downgrade.

References: [Immich v3 migration guide](https://immich.app/blog/v3-migration), [Immich v3 release notes](https://immich.app/blog/v3.0.0-release), and [Immich upgrade policy](https://docs.immich.app/install/upgrading/).

## Acceptance criteria

For every change, Argo CD must report `Synced` and `Healthy`, the workload must
be ready with no restart loop, and the component-specific smoke tests must
pass. Retain the pre-upgrade backup and the prior manifest commit until the
application has operated normally for at least one full backup cycle.

## Existing rollout safeguards

- pgAdmin 9.17 uses `/tmp/pgadmin-sessions` for transient session data because
  the existing persistent volume is not writable for the new session path.
- Hortusfox MariaDB uses `strategy: Recreate` because its iSCSI volume is
  `ReadWriteOnce`; a rolling replacement can cause a multi-attach failure.
