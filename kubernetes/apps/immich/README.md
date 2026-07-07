# Immich

Immich is exposed at `https://fotos.mauzlab.de`.

## Authentik OAuth

The Authentik OAuth provider is managed by Terraform in `terraform/authentik/apps_immich.tf`.

Apply it with:

```bash
cd terraform/authentik
terraform plan
terraform apply
```

Then configure Immich with a Secret-backed config file. The chart is set to use
`configurationKind: Secret`, but `existingConfiguration` is left disabled until
the SealedSecret exists.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: immich-config
  namespace: immich
type: Opaque
stringData:
  immich-config.yaml: |
    oauth:
      enabled: true
      issuerUrl: https://auth.mauzlab.de/application/o/immich/.well-known/openid-configuration
      clientId: immich
      clientSecret: <terraform output -raw immich_oauth_client_secret>
      scope: openid email profile
      signingAlgorithm: RS256
      profileSigningAlgorithm: none
      storageLabelClaim: preferred_username
      storageQuotaClaim: immich_quota
      buttonText: Sign in with Authentik
      autoRegister: true
      autoLaunch: false
      mobileOverrideEnabled: false
      mobileRedirectUri: ""
      tokenEndpointAuthMethod: client_secret_post
```

Seal that Secret with:

```bash
kubeseal --controller-namespace sealed-secrets --format yaml < secret.yaml > immich-config-sealed-secret.yaml
```

Then add the sealed secret to this kustomization and set:

```yaml
immich:
  configurationKind: Secret
  existingConfiguration: immich-config
  configuration: {}
```

Keep the client secret out of `immich-values.yaml`: even with
`configurationKind: Secret`, values committed to Git are still plaintext Helm
inputs.
