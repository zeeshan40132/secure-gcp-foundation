# Floci GCP Emulator Findings

## 1. Overview

This project uses [Floci GCP](https://github.com/floci-io/floci-gcp) as a local Google Cloud emulator to develop and test Terraform infrastructure without requiring a real GCP account.

The emulator provides local API endpoints for supported Google Cloud services. Terraform communicates with these endpoints through custom provider configuration.

**Important:** Successful Terraform validation, resource creation, or API responses against Floci do not prove that the equivalent resources are fully functional or that Google Cloud security controls are enforced.

## 2. Local Environment

| Component | Configuration |
|---|---|
| Emulator | Floci GCP |
| Emulator version | 0.13.0 |
| Emulator endpoint | `http://localhost:4588` |
| Default project | `floci-local` |
| Terraform | 1.17.2 |
| Google Terraform provider | 6.50.0 |
| Provider constraint | `~> 6.0` |
| Storage mode | Hybrid |
| Authentication | Local dummy access token |

The emulator runs through Docker Compose.

The local Terraform provider configuration uses:

```hcl
provider "google" {
  project      = "floci-local"
  region       = "us-central1"
  access_token = "floci-fake-token"

  storage_custom_endpoint          = "http://localhost:4588/storage/v1/"
  iam_custom_endpoint              = "http://localhost:4588/"
  secret_manager_custom_endpoint   = "http://localhost:4588/v1/"
  resource_manager_custom_endpoint = "http://localhost:4588/"
  compute_custom_endpoint          = "http://localhost:4588/compute/v1/"
}
```

The dummy token is for local emulator use only. No real GCP credentials or service account keys are used.

## 3. Emulator Health and Service Availability

The emulator health endpoint returned HTTP 200:

```bash
curl -i http://localhost:4588/_floci-gcp/health
```

The emulator reported version `0.13.0`.

The service information endpoint also returned the configured local services:

```bash
curl -s http://localhost:4588/_floci-gcp/info | python3 -m json.tool
```

The emulator reported services including:

- IAM
- Resource Manager
- Cloud Storage
- Secret Manager
- Compute Engine
- Cloud Logging
- Cloud Monitoring
- Cloud Billing
- Pub/Sub
- GKE

Service availability does not necessarily mean every API operation or runtime behavior is implemented.

## 4. Terraform Foundation Resources

The following resources were successfully created through Terraform and stored in the local emulator.

| Resource | Name | Verification |
|---|---|---|
| Cloud Storage bucket | `secure-foundation-artifacts-floci-local` | Created |
| Application service account | `secure-foundation-app` | Created |
| Secret Manager secret | `secure-foundation-app-secret` | Created |
| Custom VPC | `secure-foundation-vpc` | API verified |
| Private subnet | `secure-foundation-private-subnet` | API verified |
| Terraform plan service account | `sa-tf-plan` | Created |
| Terraform apply service account | `sa-tf-apply` | Created |
| Terraform plan custom role | `terraformPlan` | API verified |
| Terraform apply custom role | `terraformApply` | API verified |

### Cloud Storage

The artifacts bucket was configured with:

- Uniform bucket-level access enabled.
- Public access prevention enforced.
- Environment, owner, and cost-center labels.

### Service Accounts

Three dedicated service accounts exist:

- `secure-foundation-app`: application runtime identity.
- `sa-tf-plan`: intended read-only Terraform planning identity.
- `sa-tf-apply`: intended scoped Terraform deployment identity.

No service account keys were generated.

### Secret Manager

The secret container was created without adding an actual secret value.

This avoids storing unnecessary credentials or sensitive values in the local development environment.

## 5. Networking Findings

### Custom VPC

The custom VPC was successfully created:

```text
secure-foundation-vpc
```

Direct API verification confirmed:

- Custom subnet creation mode.
- Automatic subnet creation disabled.
- Regional routing mode.

### Private Subnet

The following subnet was successfully created:

| Setting | Value |
|---|---|
| Name | `secure-foundation-private-subnet` |
| Region | `us-central1` |
| CIDR | `10.10.0.0/24` |
| Private Google Access | Enabled |
| VPC Flow Logs | Configured |

The emulator API returned the expected subnet configuration, including:

- `privateIpGoogleAccess: true`
- Flow log aggregation interval of 5 seconds.
- Flow sampling of 0.5.
- Metadata inclusion set to `INCLUDE_ALL_METADATA`.

This verifies the stored configuration, not actual private Google API connectivity or flow-log telemetry.

### Firewall Rules

Three firewall rules were successfully created and verified through the Compute API.

| Firewall rule | Priority | Configuration |
|---|---:|---|
| `secure-foundation-allow-internal` | 800 | TCP, UDP, and ICMP from `10.10.0.0/24` |
| `secure-foundation-allow-iap-ssh` | 900 | TCP port 22 from `35.235.240.0/20` |
| `secure-foundation-deny-ingress` | 1000 | Deny all ingress traffic |

Lower numerical priority values take precedence over higher numerical values.

The rules are designed to:

- Permit internal subnet communication.
- Restrict SSH access to the Google IAP TCP forwarding range.
- Deny other inbound traffic by default.

**Limitation:** The emulator returned the expected firewall configurations, but actual packet filtering and IAP connectivity were not tested. API verification alone does not prove firewall enforcement.

### Cloud Router and Cloud NAT

Terraform configuration was added for:

- A regional Cloud Router named `secure-foundation-router`.
- ASN `64514`.
- Cloud NAT named `secure-foundation-nat`.
- Automatic NAT IP allocation.
- NAT limited to the private subnet.
- Error-only NAT logging.

Terraform formatting and validation succeeded.

However, attempting to access the emulator's Compute Router collection returned:

```json
{
  "error": {
    "code": 501,
    "message": "Compute collection not implemented: routers",
    "status": "UNIMPLEMENTED"
  }
}
```

Therefore:

- Cloud Router configuration is present in Terraform.
- Cloud NAT configuration is present in Terraform.
- Both resources were included in Terraform plans.
- Neither resource was successfully deployed to Floci.
- Outbound internet connectivity through Cloud NAT was not tested.

These resources remain intended real-GCP infrastructure configuration, not verified emulator resources.

## 6. IAM Findings

### Custom IAM Roles

Two project-level custom roles were created and verified through the Floci IAM API.

| Role | Purpose |
|---|---|
| `terraformPlan` | Read-only inspection of foundation resources |
| `terraformApply` | Scoped management of foundation resource types |

The Terraform apply role was hardened by removing:

```text
iam.roles.create
iam.roles.update
iam.roles.delete
```

This prevents the routine deployment identity from administering custom IAM roles.

Neither custom role grants broad project-level permissions such as `Owner` or `Editor`.

### Project-Level IAM Bindings

The following bindings were successfully created:

| Service account | Custom role |
|---|---|
| `sa-tf-plan` | `terraformPlan` |
| `sa-tf-apply` | `terraformApply` |

Direct API verification used:

```bash
curl -s -X POST \
  http://localhost:4588/v1/projects/floci-local:getIamPolicy \
  -H "Content-Type: application/json" \
  -d '{}' | python3 -m json.tool
```

The API returned HTTP 200 and confirmed both bindings.

The resulting policy contained:

```json
{
  "version": 3,
  "bindings": [
    {
      "members": [
        "serviceAccount:sa-tf-apply@floci-local.iam.gserviceaccount.com"
      ],
      "role": "projects/floci-local/roles/terraformApply"
    },
    {
      "members": [
        "serviceAccount:sa-tf-plan@floci-local.iam.gserviceaccount.com"
      ],
      "role": "projects/floci-local/roles/terraformPlan"
    }
  ]
}
```

### Secret-Level IAM Binding

Terraform successfully created a secret-level IAM member binding:

| Setting | Value |
|---|---|
| Secret | `secure-foundation-app-secret` |
| Service account | `secure-foundation-app` |
| Role | `roles/secretmanager.secretAccessor` |

The binding is managed through:

```hcl
resource "google_secret_manager_secret_iam_member" "app_secret_accessor" {
  project   = "floci-local"
  secret_id = google_secret_manager_secret.app_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.app_service_account.member
}
```

Terraform state confirms that the intended secret, member, and role are recorded.

However, directly requesting the secret-level IAM policy returned:

```text
HTTP/1.1 405 Method Not Allowed
```

The emulator therefore did not provide independent API verification of this secret-level binding through the attempted `getIamPolicy` request.

### IAM Enforcement Limitation

The project-level IAM policy and custom roles were successfully stored and verified.

The secret-level binding was successfully recorded in Terraform state, but independent API verification was unavailable.

Runtime authorization enforcement was not tested.

These results demonstrate Terraform resource management and emulator policy storage. They must not be interpreted as proof that Floci enforces the same IAM authorization behavior as real Google Cloud.

A real GCP environment is required to validate effective permissions and runtime access restrictions.

## 7. Terraform Provider Endpoint Issue

During project IAM binding creation, Terraform initially attempted to call:

```text
/v1/v1/projects/floci-local:getIamPolicy
```

The correct Floci endpoint was:

```text
/v1/projects/floci-local:getIamPolicy
```

The issue was caused by the Resource Manager custom endpoint configuration containing an additional `/v1/` prefix.

The configuration was corrected from:

```hcl
resource_manager_custom_endpoint = "http://localhost:4588/v1/"
```

to:

```hcl
resource_manager_custom_endpoint = "http://localhost:4588/"
```

After the correction, Terraform successfully created both project-level IAM member bindings.

This was a provider endpoint compatibility issue rather than a failure of the project IAM policy endpoint itself.

## 8. Terraform Validation and Deployment Scope

The following Terraform operations have been performed successfully:

- `terraform fmt`
- `terraform validate`
- `terraform init`
- `terraform plan`
- Targeted Terraform applies for supported emulator resources.

Some resources required targeted applies because the emulator does not implement every configured Google Cloud API.

Targeted applies were used only to isolate supported resources and avoid attempting unsupported Cloud Router and Cloud NAT operations.

A complete, un-targeted apply of the entire configuration has not been demonstrated as successful.

A fresh Terraform plan should be run to identify any remaining changes.

## 9. Security and Testing Boundaries

The following distinctions are important when evaluating this project:

| Capability | Current result |
|---|---|
| Terraform syntax and validation | Verified |
| Local emulator health | Verified |
| Supported resource creation | Verified |
| VPC and subnet configuration | API verified |
| Firewall rule configuration | API verified |
| Cloud Router and NAT deployment | Not supported by emulator |
| Project-level IAM policy storage | API verified |
| Secret-level IAM policy verification | API returned 405 |
| IAM authorization enforcement | Not tested |
| Actual network packet filtering | Not tested |
| Actual private Google API connectivity | Not tested |
| Real GCP deployment | Not performed |

The emulator is useful for local development, Terraform provider integration, and testing supported API operations. It is not a replacement for a real GCP environment when validating cloud networking, authorization enforcement, or production security behavior.

## 10. Conclusion

Floci GCP has enabled local development of the Secure GCP Foundation project without a real GCP account.

The project successfully created and verified supported foundation resources, configured a custom network and firewall rules, created dedicated service accounts and custom IAM roles, and stored project-level IAM bindings.

Cloud Router and Cloud NAT remain configured but undeployed because their Compute API collection is not implemented by the emulator. Secret-level IAM policy retrieval and runtime authorization enforcement also remain unverified.

These limitations are documented explicitly so that the project demonstrates what was actually implemented and tested without overstating emulator capabilities.