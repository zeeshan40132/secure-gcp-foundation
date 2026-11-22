# ADR 0002: Floci as the Local GCP Emulator

- **Status:** Accepted
- **Date:** 2026-11-22

## Context

The project requires testing Google Cloud infrastructure without creating or using a real GCP account.

A local emulator provides an environment for experimenting with supported Google Cloud APIs while avoiding real cloud provisioning and associated costs.

## Decision

Use **Floci GCP** through Docker Compose as the local API emulator.

Configure the Terraform Google provider to communicate with the emulator's supported custom API endpoints.

Use Terraform state and direct API responses to inspect resources created in the emulator.

Document unsupported APIs and capabilities in `docs/emulator-findings.md`.

## Alternatives Considered

- **Real Google Cloud project:** Not selected because the project explicitly avoids requiring a real GCP account.
- **Terraform validation only:** Useful for syntax and configuration checks, but does not provide API-level resource testing.
- **Other local emulators:** Not selected because Floci provides the local GCP API testing environment used by this project.

## Consequences

### Positive

- Infrastructure experiments can run locally.
- Supported resource APIs can be tested without real cloud provisioning.
- Docker Compose makes the emulator easier to start and stop.
- API responses provide additional evidence beyond Terraform validation.

### Trade-offs and Limitations

- Floci does not implement every Google Cloud API.
- Successful resource creation does not prove production behavior or runtime security enforcement.
- Some IAM policy retrieval and authorization capabilities remain unverified.
- Cloud Router and Cloud NAT could not be deployed because the required router API is unsupported.
- Real GCP testing is still required before production use.