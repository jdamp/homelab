# Authentik SSO Expansion Checklist

This checklist tracks services that are deployed in the homelab but are not
currently integrated with Authentik.

Already integrated: Argo CD, Grafana, Homepage, Immich, Linkding, Mealie,
Paperless-ngx, pgAdmin, and Planka.

## Shared preparation

- [ ] Confirm the `homelab-users` and `homelab-admins` Authentik groups are the
      correct access-control groups for each new application.
- [ ] Keep OAuth client secrets in SealedSecrets; do not commit them in plain
      Kubernetes or Helm values.
- [ ] Add each native OIDC client under `terraform/authentik/apps_<app>.tf`,
      following the existing `modules/oauth_app` pattern.
- [ ] Preserve a tested local or break-glass administrator account before
      disabling password login in any service.
- [ ] Test login, logout, session expiry, group removal, and account linking
      before enforcing SSO-only access.
- [ ] Document recovery steps and the expected callback URL for every client.

## Priority 1: Homepage

Integration type: native OIDC.

- [x] Create an Authentik OAuth2/OIDC provider and application for Homepage.
- [x] Configure the callback URL:
      `https://home.mauzlab.de/api/auth/callback/homepage-oidc`.
- [x] Add a SealedSecret containing the client ID, client secret, and a stable
      `HOMEPAGE_AUTH_SECRET` of at least 32 characters.
- [x] Add `HOMEPAGE_AUTH_ENABLED=true`.
- [x] Add `HOMEPAGE_EXTERNAL_URL=https://home.mauzlab.de`.
- [x] Add `HOMEPAGE_OIDC_ISSUER` using the Authentik application issuer URL.
- [x] Add `HOMEPAGE_OIDC_CLIENT_ID` and `HOMEPAGE_OIDC_CLIENT_SECRET` from the
      SealedSecret.
- [x] Set `HOMEPAGE_OIDC_NAME=Authentik`.
- [ ] Verify all dashboard pages and API-backed widgets still work after login.

## Priority 2: Linkding

Integration type: native OIDC with automatic user creation.

- [x] Create an Authentik OAuth2/OIDC provider and application for Linkding.
- [x] Configure the callback URL:
      `https://links.mauzlab.de/oidc/callback/`.
- [x] Add a SealedSecret for `OIDC_RP_CLIENT_ID` and
      `OIDC_RP_CLIENT_SECRET`.
- [x] Add `LD_ENABLE_OIDC=True`.
- [x] Configure the Authentik authorization, token, userinfo, and JWKS
      endpoints through the corresponding `OIDC_OP_*` variables.
- [x] Set `OIDC_USERNAME_CLAIM=preferred_username`, if usernames rather than
      email addresses should be used for newly created accounts.
- [x] Ensure the existing administrator account has an email matching the
      Authentik identity before its first OIDC login.
- [x] Verify interactive browser login through Authentik.
- [ ] Verify the browser extension and API-token clients continue to work.
- [ ] After validating the break-glass account, consider setting
      `LD_DISABLE_LOGIN_FORM=True`.

## Priority 3: pgAdmin

Integration type: native OIDC.

- [x] Create an Authentik OAuth2/OIDC provider and application for pgAdmin.
- [x] Configure the callback URL:
      `https://pgadmin.mauzlab.de/oauth2/authorize`.
- [x] Store the complete OAuth provider configuration, including the client
      secret, in a SealedSecret.
- [x] Set `PGADMIN_CONFIG_AUTHENTICATION_SOURCES` to include `oauth2` and keep
      `internal` during rollout.
- [x] Set the complete provider list through
      `PGADMIN_CONFIG_OAUTH2_CONFIG`; pgAdmin does not accept the individual
      provider settings as separate top-level variables.
- [x] Use Authentik's OIDC discovery URL and request `openid email profile`.
- [x] Enable the authorization-code flow with S256 PKCE.
- [x] Enable automatic pgAdmin user creation.
- [x] Restrict access through Authentik application bindings for
      `homelab-users` and `homelab-admins`.
- [x] Pre-create the OIDC user as a pgAdmin administrator and copy the existing
      server registration without a saved database password.
- [x] Verify the OIDC administrator can log in.
- [ ] Verify the local break-glass administrator can still log in before
      considering removal of `internal` authentication.

## Priority 4: Vaultwarden

Integration type: native OIDC with a separate vault master password.

- [x] Confirm a current shared-database backup and create a pre-SSO `/data`
      archive.
- [x] Create an Authentik OAuth2/OIDC provider and application for
      Vaultwarden.
- [x] Configure the callback URL:
      `https://passwort.mauzlab.de/identity/connect/oidc-signin`.
- [x] Add a SealedSecret for `SSO_CLIENT_ID` and `SSO_CLIENT_SECRET`.
- [x] Set `SSO_ENABLED=true` and configure `SSO_AUTHORITY` to the exact
      Authentik issuer URL.
- [x] Request `openid`, `profile`, `email`, and `offline_access`; use a
      provider-specific email mapping that supplies `email_verified=true`.
- [x] Enable PKCE and confirm Vaultwarden redirects to Authentik with the
      expected client, callback, and scopes.
- [x] Confirm the existing Vaultwarden account email matches the Authentik
      identity before first SSO login.
- [ ] Test linking with an existing Vaultwarden account before enabling
      `SSO_ONLY` or changing signup behavior.
- [ ] Verify web vault, browser extension, and mobile-client login flows.
- [ ] Confirm users understand that the vault master password is still needed
      to decrypt vault contents after Authentik login.
- [x] Retain email/master-password login by keeping `SSO_ONLY=false`.
- [ ] Test the retained email/master-password login after SSO account linking.

## Priority 5: HortusFox

Integration type: Authentik forward auth with trusted identity headers.

- [ ] Create an Authentik proxy provider and application for HortusFox.
- [ ] Use single-application forward-auth mode with external host
      `https://kratzbaum.mauzlab.de`.
- [ ] Assign the proxy application to the embedded or a managed Authentik
      outpost.
- [ ] Create a Traefik `Middleware` that calls the Authentik outpost and copies
      the `X-authentik-*` response headers.
- [ ] Attach the middleware to the HortusFox `IngressRoute`.
- [ ] Route `/outpost.goauthentik.io/` to the Authentik outpost without applying
      the forward-auth middleware to that path.
- [ ] Set `PROXY_ENABLE=true`.
- [ ] Set `PROXY_HEADER_EMAIL=X-authentik-email` and
      `PROXY_HEADER_USERNAME=X-authentik-username`.
- [ ] Set and review `PROXY_AUTO_SIGNUP`, `PROXY_HIDE_LOGOUT`, and
      `PROXY_OVERWRITE_VALUES` behavior.
- [ ] Ensure HortusFox cannot be reached through a path that bypasses Traefik,
      preventing clients from spoofing trusted identity headers.
- [ ] Verify user creation, administrator assignment, logout, and removal of
      Authentik access.

## Optional community integrations

### Home Assistant

- [ ] Decide whether accepting a HACS-managed custom authentication component
      is appropriate; Home Assistant does not provide a built-in OIDC client.
- [ ] Evaluate `christiaangoossens/hass-oidc-auth` with Authentik.
- [ ] Back up the Home Assistant configuration and retain the built-in
      `homeassistant` auth provider during rollout.
- [ ] Test browser, companion-app, callback, token refresh, and recovery flows.
- [ ] Only block other login methods after the OIDC path is proven reliable.

### Jellyfin

- [ ] Decide whether accepting a beta-channel community plugin is appropriate.
- [ ] Evaluate the Flowfin Community SSO plugin, which supports Jellyfin 10.11
      and Authentik.
- [ ] Create an Authentik provider with the plugin's documented callback URL.
- [ ] Configure group-to-user, administrator, and library-access mappings.
- [ ] Test the web UI and every used Jellyfin client; client SSO support varies
      and may rely on Quick Connect.
- [ ] Keep a break-glass Jellyfin administrator outside SSO enforcement.

## MLflow security follow-up

MLflow is currently exposed without an authentication application. Native
OIDC is not available, and adding SSO requires a community plugin or a carefully
designed proxy setup that also accounts for SDK and API clients.

- [ ] Treat MLflow authentication as a separate security task rather than a
      quick SSO change.
- [ ] Evaluate `mlflow-oidc-auth`, including its authentication database,
      session secrets, group mapping, and client compatibility.
- [ ] Replace startup-time package installation with a pinned custom container
      image if the plugin is adopted.
- [ ] Define authentication for browser, Python SDK, automation, and health
      endpoints before enabling enforcement.

## Not currently recommended as SSO projects

- [ ] Revisit Uptime Kuma if it gains native OIDC support. A forward-auth gate
      alone is not application-level SSO and may interfere with status pages or
      integrations.
- [ ] Revisit AdGuard Home if it gains native OIDC or trusted-header support. A
      forward-auth gate would add an outer login without replacing its local
      application authentication.

## Completion checks

- [ ] Run `terraform fmt -check` and `terraform validate` for the Authentik
      configuration.
- [ ] Render every changed Kubernetes application with Kustomize/Helm support
      enabled and review the generated resources.
- [ ] Confirm no plaintext OAuth client secret appears in Git or rendered
      non-Secret resources.
- [ ] Sync one application at a time and verify its health before proceeding.
- [ ] Confirm removing a user from `homelab-users` revokes new access as
      expected after existing sessions expire or are invalidated.
- [ ] Update this checklist and the Authentik Terraform README as integrations
      are completed.
