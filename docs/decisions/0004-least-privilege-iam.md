# ADR 0004: Least-Privilege IAM and Service Account Separation

- **Status:** Accepted
- **Date:** 2026-11-22

## Context

The foundation requires different identities for infrastructure planning, infrastructure management, and application runtime access.

Using one broadly privileged service account for every task would increase the impact of compromised credentials and make permissions harder to audit.

## Decision

Use separate service accounts with distinct responsibilities:

| Service Account | Responsibility |
|---|---|
| `sa-tf-plan` | Read-only infrastructure inspection |
| `sa-tf-apply` | Scoped infrastructure management |
| `secure-foundation-app` | Application runtime identity |

Define custom project roles for Terraform planning and applying.

Grant the application service account `roles/secretmanager.secretAccessor` at the individual secret level rather than granting project-wide access.

Avoid primitive project roles such as Owner, Editor, and Viewer.

## Alternatives Considered

- **One shared service account:** Rejected because it combines unrelated permissions and increases security risk.
- **Primitive project roles:** Rejected because they grant broader permissions than the intended responsibilities require.
- **Project-wide Secret Manager access:** Rejected because access should be limited to the specific secret.

## Consequences

### Positive

- Separates infrastructure and application identities.
- Supports least-privilege access design.
- Reduces unnecessary permission sharing.
- Makes IAM responsibilities easier to review and document.

### Trade-offs and Limitations

- Custom roles require careful permission maintenance.
- Some emulator IAM capabilities are incomplete.
- Terraform state records configured bindings, but does not prove runtime authorization enforcement.
- Secret-level IAM policy retrieval could not be independently verified through the emulator.