# ADR 0001: Terraform for Infrastructure as Code

- **Status:** Accepted
- **Date:** 2026-11-22

## Context

The Secure GCP Foundation project requires repeatable infrastructure provisioning, version-controlled configuration, and automated validation.

The project must also work without a real Google Cloud account, using a local GCP emulator for supported APIs.

## Decision

Use **Terraform** with the official Google Cloud provider to define infrastructure declaratively.

Terraform configuration is organized into separate files for networking, IAM, storage, secrets, and provider settings.

The local provider configuration targets the Floci GCP emulator. Terraform initialization and validation are also performed in CI without requiring real cloud credentials.

## Alternatives Considered

- **Google Cloud Console:** Manual configuration would be difficult to reproduce, review, and validate.
- **Google Cloud Deployment Manager:** Not selected because Terraform better fits the project's provider-based, version-controlled workflow.
- **OpenTofu:** A viable alternative, but Terraform was selected to keep the project aligned with the requested tooling.

## Consequences

### Positive

- Infrastructure is declarative and version-controlled.
- Changes can be reviewed through pull requests.
- Terraform plans and validation support repeatable workflows.
- Security checks can inspect infrastructure configuration before deployment.

### Trade-offs and Limitations

- Some Google Cloud APIs are not implemented by the Floci emulator.
- Terraform state must be protected and excluded from Git.
- Successful validation does not prove that every resource can be deployed to real GCP.
- Production deployment requires real credentials, backend configuration, and cloud-side verification.