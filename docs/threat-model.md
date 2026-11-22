# STRIDE-Lite Threat Model

## 1. Overview

This document identifies the primary security threats affecting the Secure GCP Foundation project and maps them to implemented security controls, planned mitigations, and known limitations.

The project uses Terraform to define a secure Google Cloud foundation, a local Floci GCP emulator for infrastructure testing, Checkov for static security analysis, custom Python policies, and GitHub Actions for CI enforcement.

No real GCP project or credentials are used.

## 2. System Assets

The assets requiring protection include:

| Asset | Security objective |
|---|---|
| Terraform configuration | Prevent unauthorized or insecure infrastructure changes |
| Google Cloud Storage buckets | Maintain data confidentiality and integrity |
| Secret Manager | Protect application secrets |
| Service accounts | Prevent unauthorized identity usage |
| IAM policies and custom roles | Enforce least privilege |
| VPC and firewall rules | Restrict network access |
| GitHub repository | Protect infrastructure source code |
| CI/CD workflow | Reject insecure Terraform changes |
| Audit logs | Provide accountability and investigation evidence |

## 3. Trust Boundaries

The architecture contains these trust boundaries:

1. **Developer workstation:** Terraform code is written and validated locally.
2. **GitHub repository:** Source code and infrastructure changes are reviewed through pull requests.
3. **GitHub Actions:** Automated validation and security checks execute in an isolated CI runner.
4. **Cloud identity boundary:** Workload Identity Federation is configured to restrict GitHub OIDC trust to the intended repository and branches.
5. **GCP resource boundary:** Storage, IAM, networking, and Secret Manager resources are defined in Terraform.
6. **Local emulator boundary:** Floci simulates supported GCP APIs but does not prove real Google Cloud security enforcement.

## 4. STRIDE Threat Analysis

### S — Spoofing

**Threat:** An attacker impersonates a developer, GitHub Actions workflow, or service account.

Potential attack scenarios:
- Compromised GitHub account submits malicious Terraform changes.
- Unauthorized GitHub repository attempts to use the WIF provider.
- Leaked service account credentials are used to access cloud resources.

Security controls:
- GitHub branch protection requires pull requests.
- CI checks must pass before merging.
- WIF provider condition restricts trusted repository identity.
- Separate Terraform plan, apply, and application service accounts.
- Service account key resources are prohibited by custom policy.

Verification:
- GitHub branch protection verified.
- WIF configuration passes static policy checks.
- No real OIDC token exchange performed.

### T — Tampering

**Threat:** An attacker modifies infrastructure or application configuration without authorization.

Potential attack scenarios:
- A developer introduces an unrestricted firewall rule.
- An attacker changes IAM assignments to grant excessive permissions.
- A malicious change disables required security controls.

Security controls:
- Terraform infrastructure as code.
- GitHub pull-request workflow.
- Checkov static analysis.
- Custom policies prohibit public SSH/RDP, primitive IAM roles, and public principals.
- Branch protection prevents ordinary direct changes to main.

Verification:
- Public SSH negative-test pull request was rejected by both Checkov and the custom policy checker.
- Terraform configuration validation passes for the compliant infrastructure.

### R — Repudiation

**Threat:** A user denies performing an infrastructure or identity-related action because insufficient audit evidence exists.

Potential attack scenarios:
- An unauthorized IAM policy modification cannot be attributed.
- Service account key creation goes unnoticed.
- Firewall changes cannot be traced during an incident.

Planned security controls:
- Enable Cloud Audit Logs for IAM and Secret Manager Data Access events.
- Configure a dedicated Cloud Storage logging destination.
- Create log-based metrics for IAM policy changes, service account key creation, and firewall changes.
- Retain audit evidence for investigation.

Verification:
- Logging and monitoring resources remain subject to implementation and emulator capability testing.
- Runtime audit event generation has not been demonstrated.

### I — Information Disclosure

**Threat:** Sensitive information is exposed to unauthorized users.

Potential attack scenarios:
- A storage bucket becomes publicly accessible.
- An application identity gains access to unrelated secrets.
- Sensitive credentials are committed to GitHub.
- Network rules expose internal services.

Security controls:
- Uniform bucket-level access.
- Public access prevention enforced on storage buckets.
- Secret Manager used as the secret container.
- Application service account receives secretAccessor at the individual secret level.
- No real credentials or service account key files are committed.
- Private Google Access enabled on the private subnet.

Verification:
- Storage configuration and Terraform IAM state inspected.
- Secret-level IAM policy retrieval is not supported by the current emulator, so runtime authorization remains unverified.

### D — Denial of Service

**Threat:** An attacker exhausts resources or disrupts service availability.

Potential attack scenarios:
- Excessive resource provisioning increases cloud expenditure.
- Network misconfiguration prevents legitimate connectivity.
- Infrastructure resources are deleted or become unavailable.

Security controls:
- Terraform-managed infrastructure.
- Dedicated private network and subnet.
- Cloud NAT configuration defined for outbound connectivity.
- Planned billing budgets and monitoring alerts.
- Resource labels for cost attribution.

Verification:
- VPC and subnet configuration persisted in Floci.
- Cloud Router and Cloud NAT deployment is unverified because the emulator does not implement the required router API.
- Billing thresholds and notifications have not been demonstrated.

### E — Elevation of Privilege

**Threat:** A user or service account obtains permissions beyond its intended responsibilities.

Potential attack scenarios:
- Terraform plan identity receives write permissions.
- Application service account receives project-wide access to secrets.
- An identity receives primitive Editor or Owner permissions.
- A deployment identity modifies its own permission model.

Security controls:
- Separate plan and apply service accounts.
- Custom Terraform plan and apply roles.
- Application secret access scoped to an individual secret.
- Primitive project IAM roles prohibited by custom policy.
- Apply role excludes IAM role administration permissions.
- WIF apply identity restricted to the main branch.

Verification:
- Service accounts and project IAM bindings persisted in Floci.
- IAM runtime authorization enforcement has not been demonstrated.

## 5. Risk Summary

| Threat | Risk | Primary mitigation |
|---|---|---|
| Spoofing | High | WIF restrictions and identity separation |
| Tampering | High | Branch protection and policy-as-code |
| Repudiation | Medium | Audit logging and monitoring |
| Information disclosure | High | Private storage, Secret Manager and least privilege |
| Denial of service | Medium | Cost controls and monitoring |
| Elevation of privilege | High | Custom IAM roles and restricted permissions |

Risk levels represent qualitative design assessments, not results from a formal quantitative risk assessment.

## 6. Known Limitations

- No production GCP environment was used.
- WIF token exchange has not been tested against Google Cloud.
- Floci does not support every Compute Engine API required by this project.
- IAM policy persistence in the emulator does not prove authorization enforcement.
- Audit logging and monitoring behavior requires further validation.
- Budget alerts cannot be fully validated without real billing activity.

## 7. Conclusion

The project applies defense-in-depth through infrastructure as code, least-privilege identity design, private networking, static security analysis, custom policy enforcement, and protected CI/CD workflows.

The negative-test pull request demonstrated that both Checkov and the custom Python policy checker detect publicly exposed SSH ingress and cause the GitHub Actions workflow to fail.

Remaining controls will be implemented and evaluated according to emulator capabilities, with unverified behavior explicitly documented.
