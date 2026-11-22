# Security Test Results

## Overview

This document records the negative security tests implemented for the Secure GCP Foundation project.

The tests verify that the custom Terraform policy checker rejects known insecure infrastructure configurations while accepting the compliant infrastructure configuration.

## Test Environment

- Terraform: 1.17.2
- Google Terraform provider: 6.50.0
- Checkov: 3.4.6
- Custom policy engine: Python 3
- Infrastructure target: Local Floci GCP emulator configuration
- Real GCP deployment: Not performed

## Positive Test — Compliant Infrastructure

The custom policy checker was executed against the actual `infra/` directory.

| Policy | Result |
|---|---|
| Service account key prohibition | PASS |
| Mandatory resource labels | PASS |
| Primitive IAM role prohibition | PASS |
| Public IAM principal prohibition | PASS |
| WIF trust condition | PASS |
| Firewall ingress restrictions | PASS |

**Result: 6 passed, 0 failed.**

## Negative Security Tests

Five intentionally insecure Terraform fixtures were tested independently.

| Test fixture | Security violation | Expected result | Actual result |
|---|---|---|---|
| `public-ssh.tf` | SSH exposed to `0.0.0.0/0` | Reject | PASS |
| `service-account-key.tf` | Service account key resource | Reject | PASS |
| `missing-labels.tf` | Required resource labels absent | Reject | PASS |
| `wif-no-condition.tf` | WIF provider missing attribute condition | Reject | PASS |
| `primitive-iam-role.tf` | Project-level `roles/editor` assignment | Reject | PASS |

Each fixture triggered exactly one intended policy failure. The other five policy checks passed for each isolated test.

**Result: 5 of 5 negative tests detected.**

## Checkov Results

The Terraform configuration was scanned using Checkov 3.4.6.

- Passed checks: 44
- Failed checks: 0
- Skipped checks: 1

The single skipped check concerns access logging on the dedicated access-log destination bucket. Self-logging would create recursive logging, so the exception is documented inline in Terraform.

## CI Pipeline

The GitHub Actions workflow `.github/workflows/terraform-ci.yml` runs:

1. Terraform formatting validation.
2. Terraform initialization.
3. Terraform configuration validation.
4. Checkov security scanning.
5. Custom Python policy tests, including all five negative fixtures.

The workflow is configured to run on pull requests targeting `main` and pushes to `main`.

## Limitations

- Tests validate Terraform source configuration; they do not prove runtime security enforcement in Google Cloud.
- The WIF negative test validates static Terraform configuration, not a real GitHub OIDC token exchange.
- No real GCP project or credentials were used.
- The negative tests are local automated fixtures, not five separately submitted GitHub pull requests.

## Conclusion

The policy-as-code checks accept the current compliant Terraform configuration and reject all five tested insecure configurations. Checkov reports zero failed checks, and the custom policy suite successfully detects the expected violations.