# ADR 0005: GitHub Actions and Automated Security Policies

- **Status:** Accepted
- **Date:** 2026-11-22

## Context

Infrastructure changes need automated validation before they can be merged into the protected `main` branch.

Terraform formatting and validation alone do not detect every security misconfiguration. The project therefore requires static infrastructure scanning and project-specific security policies.

## Decision

Use GitHub Actions to run the Terraform CI pipeline for pull requests targeting `main` and pushes to `main`.

The pipeline performs:

1. Terraform formatting checks.
2. Terraform initialization with the remote backend disabled.
3. Terraform configuration validation.
4. Checkov security scanning.
5. Custom Python policy tests.

Use Checkov for established Terraform security checks and custom Python policies for project-specific guardrails.

Require the CI status check to pass before merging pull requests into the protected `main` branch.

Validate policy enforcement with intentionally insecure test fixtures, including unrestricted SSH ingress, primitive IAM roles, public IAM principals, missing labels, service account keys, and missing WIF conditions.

## Alternatives Considered

- **Manual code review only:** Rejected because it cannot consistently detect every security misconfiguration.
- **Terraform validation only:** Rejected because syntactically valid infrastructure can still violate security requirements.
- **Checkov alone:** Rejected because custom project-specific policies are also required.

## Consequences

### Positive

- Security checks run consistently during code review.
- Misconfigurations can be detected before merging.
- Custom policies enforce project-specific requirements.
- Negative tests demonstrate that insecure configurations are rejected.
- Branch protection makes successful CI a merge requirement.

### Trade-offs and Limitations

- Static analysis cannot prove runtime security.
- Some Checkov rules may require documented exceptions.
- CI validation does not prove successful deployment to real GCP.
- Production deployment would require additional integration and runtime tests.