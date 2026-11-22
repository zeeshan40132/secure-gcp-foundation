# Troubleshooting and Development Findings

This document records actual issues encountered while developing the Secure GCP Foundation project, along with their root causes, resolutions, and lessons learned.

## 1. Floci Cloud Router API Returned HTTP 501

**Component:** Terraform / Floci GCP Emulator

**Symptom:**

Terraform configuration for Cloud Router and Cloud NAT was available, but requests to the emulator's Compute API router endpoint returned HTTP 501:

```text
Compute collection not implemented: routers
```

**Root Cause:**

The Floci GCP emulator does not implement the required Cloud Router API collection.

**Resolution:**

- Inspected the emulator API response.
- Confirmed the unsupported router API.
- Kept the Cloud Router and Cloud NAT Terraform configuration for architectural completeness.
- Did not apply these resources against the emulator.
- Documented the limitation in `docs/emulator-findings.md`.

**Lesson Learned:**

Terraform resource definitions do not guarantee that the target provider or emulator supports the corresponding API. Verify API support before attempting deployment.

## 2. Unsupported Labels on Compute Subnetworks

**Component:** Terraform / Google Cloud Provider

**Symptom:**

The subnet configuration initially attempted to use resource labels, but the Terraform provider schema did not support a `labels` argument for `google_compute_subnetwork`.

**Root Cause:**

Not every Google Cloud resource type exposes the same configurable attributes through the Terraform provider.

**Resolution:**

- Removed the unsupported labels argument from the subnet resource.
- Retained common labels on supported resources.
- Updated the custom policy checker so it does not require labels on unsupported resource types.

**Lesson Learned:**

Security policies must account for the actual capabilities of each resource type. Applying a universal requirement without checking provider schemas can produce invalid configurations.

## 3. Custom Policy Tests Were Skipped After Checkov Failed

**Component:** GitHub Actions / Checkov / Custom Python Policies

**Symptom:**

During the public SSH negative-test pull request, Checkov detected unrestricted SSH ingress and failed the CI step.

The custom Python policy test step did not run because the workflow stopped after the failed Checkov step.

**Root Cause:**

GitHub Actions normally skips subsequent steps when an earlier step fails, unless an execution condition overrides that behavior.

**Resolution:**

On the temporary negative-test branch, the custom policy step was updated with:

```yaml
if: always()
```

The workflow was rerun. Checkov rejected the public SSH rule, and the custom Python checker independently reported:

```text
[FAIL] Firewall ingress restrictions
- negative-test.tf: firewall insecure_public_ssh allows unrestricted SSH ingress
```

The negative-test pull request was closed without merging.

**Implementation Note:**

The `if: always()` change was tested on the temporary negative-test branch and was not merged into `main`. The committed main workflow should therefore not be assumed to contain this change.

**Lesson Learned:**

Independent security checks should be designed to run even when another scanner fails, so that CI provides complete diagnostic feedback.

## 4. Terraform Registry Initialization Timeout

**Component:** Terraform Provider Installation

**Symptom:**

A Terraform initialization attempt failed because the Terraform provider registry could not be reached before the request timed out.

**Root Cause:**

The failure was a transient registry connectivity issue rather than a confirmed Terraform configuration error.

**Resolution:**

Retried Terraform initialization. The retry succeeded using the available provider cache and committed dependency lock file.

**Lesson Learned:**

Distinguish transient dependency-download failures from configuration errors. Committing `.terraform.lock.hcl` also helps maintain consistent provider selections across environments.

## Summary

| Issue | Root Cause | Outcome |
|---|---|---|
| Cloud Router API HTTP 501 | Unsupported emulator API | Documented; deployment skipped |
| Subnetwork labels | Unsupported provider argument | Removed and policy adjusted |
| Custom policy step skipped | GitHub Actions failure behavior | Tested `if: always()` on temporary branch |
| Terraform init timeout | Transient registry connectivity | Retry succeeded |

These findings demonstrate the importance of verifying provider capabilities, understanding CI execution behavior, and documenting emulator limitations rather than claiming unsupported functionality.