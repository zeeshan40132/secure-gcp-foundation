# IAM Roles and Identity Architecture

## 1. Overview

This project follows the principle of least privilege by separating Terraform planning, infrastructure deployment, and application runtime identities.

Each identity has a specific purpose and receives only the permissions required for that purpose.

## 2. Service Accounts

| Service account | Purpose |
|---|---|
| `sa-tf-plan` | Read-only infrastructure inspection and Terraform planning |
| `sa-tf-apply` | Scoped infrastructure provisioning and management |
| `secure-foundation-app` | Application runtime identity |

No service account keys are generated or stored in the repository.

## 3. Custom IAM Roles

### Terraform Plan Role

**Role ID:** `terraformPlan`

**Purpose:** Allow Terraform to inspect existing infrastructure and calculate execution plans without granting resource modification permissions.

The role includes read permissions for:

- Project metadata.
- Compute networks, subnetworks, firewalls, and routers.
- Cloud Storage buckets.
- Service accounts and custom IAM roles.
- Secret Manager secrets.

It does not include resource creation, modification, or deletion permissions.

### Terraform Apply Role

**Role ID:** `terraformApply`

**Purpose:** Allow Terraform to manage the resource types used by this foundation project.

The role includes scoped permissions for:

- Compute networks.
- Compute subnetworks.
- Compute firewall rules.
- Cloud Routers and Cloud NAT.
- Cloud Storage buckets.
- Service accounts.
- Custom IAM role inspection.
- Secret Manager secret management.

The role deliberately excludes:

- Custom IAM role creation, modification, and deletion.
- Project-level IAM policy administration.
- Broad primitive roles such as `Owner`, `Editor`, and `Viewer`.

Custom role administration and project-level IAM policy changes are reserved for a separate privileged bootstrap identity.

## 4. IAM Bindings

### Project-Level Bindings

The following custom roles are assigned at project level:

| Member | Role |
|---|---|
| `serviceAccount:sa-tf-plan@floci-local.iam.gserviceaccount.com` | `projects/floci-local/roles/terraformPlan` |
| `serviceAccount:sa-tf-apply@floci-local.iam.gserviceaccount.com` | `projects/floci-local/roles/terraformApply` |

Terraform manages these bindings using `google_project_iam_member`.

### Secret-Level Binding

The application service account receives:

| Setting | Value |
|---|---|
| Resource | `secure-foundation-app-secret` |
| Member | `secure-foundation-app` |
| Role | `roles/secretmanager.secretAccessor` |
| Scope | Individual secret |

Terraform manages this binding using `google_secret_manager_secret_iam_member`.

This avoids granting the application access to every secret in the project.

## 5. Privileged Bootstrap Separation

The initial creation of custom IAM roles and project-level IAM bindings requires a privileged bootstrap identity.

The routine Terraform apply identity is intentionally not granted permission to administer project IAM policies or modify custom role definitions.

In a real GCP deployment, the bootstrap process should use a separately controlled administrative identity to:

1. Create the custom IAM roles.
2. Create the dedicated service accounts.
3. Attach the appropriate project-level IAM bindings.
4. Configure resource-level IAM bindings.
5. Verify the resulting permissions.

Routine infrastructure deployments should then use the dedicated Terraform apply identity.

The local emulator uses a dummy access token, so this project does not demonstrate real GCP identity impersonation or authorization enforcement.

## 6. Security Decisions

### Least Privilege

Separate identities prevent planning, deployment, and application workloads from sharing one broad permission set.

### Additive IAM Management

The project uses `google_project_iam_member` and `google_secret_manager_secret_iam_member` rather than authoritative IAM policy resources.

This reduces the risk of unintentionally replacing unrelated IAM members.

### No Primitive Roles

Broad primitive roles such as `Owner`, `Editor`, and `Viewer` are not assigned to the Terraform service accounts.

### No Service Account Keys

Service account keys are not generated. Future CI/CD authentication is intended to use Workload Identity Federation rather than long-lived service account credentials.

### Resource-Level Secret Access

The application receives the Secret Manager accessor role on its designated secret instead of at project level.

## 7. Verification and Limitations

The following checks were completed against Floci:

- Three service accounts were created.
- Both custom IAM roles were created and their permissions inspected.
- The Terraform apply role was updated to remove custom role administration permissions.
- Both project-level IAM bindings were returned by the Floci `getIamPolicy` endpoint.
- Terraform state records the application secret-level IAM binding.

Limitations:

- Floci's project-level IAM policy API confirmed stored bindings, but runtime authorization enforcement was not tested.
- The attempted secret-level `getIamPolicy` request returned HTTP 405.
- Secret-level policy persistence could not be independently verified through that API.
- No real GCP deployment or service account impersonation was performed.

See [emulator-findings.md](emulator-findings.md) for detailed emulator behavior and limitations.
