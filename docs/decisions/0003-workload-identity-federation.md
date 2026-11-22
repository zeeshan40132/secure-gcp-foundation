# ADR 0003: Workload Identity Federation for GitHub Actions

- **Status:** Accepted
- **Date:** 2026-11-22

## Context

GitHub Actions needs an identity mechanism to access Google Cloud resources during infrastructure automation.

Long-lived service account keys introduce credential exposure and rotation risks. The project therefore aims to use short-lived federated credentials instead.

## Decision

Define a Google Cloud Workload Identity Federation configuration that trusts GitHub Actions through its OIDC identity provider.

Use the following design:

- OIDC issuer: `https://token.actions.githubusercontent.com`
- Restrict the provider condition to the `zeeshan40132/secure-gcp-foundation` repository.
- Permit pull-request and main-branch subjects.
- Associate the plan service account with the repository's federated identity.
- Restrict the apply service account to the main branch through an additional IAM condition.

The configuration is maintained in Terraform.

## Alternatives Considered

- **Service account JSON keys:** Rejected because long-lived credentials increase the risk of accidental exposure.
- **Static credentials in GitHub Secrets:** Rejected for the same long-lived credential risks.
- **No cloud identity integration:** Would not demonstrate the intended federated authentication architecture.

## Consequences

### Positive

- Avoids designing CI around long-lived service account keys.
- Establishes repository-specific trust conditions.
- Separates infrastructure planning and application of changes.
- Limits the apply identity to the main branch in the configured IAM binding.

### Trade-offs and Limitations

- The configuration has not been deployed to a real GCP project.
- Actual GitHub OIDC token exchange has not been tested.
- Provider conditions and IAM bindings require real cloud-side verification.
- Production use requires a correctly configured GCP project and federated identity permissions.