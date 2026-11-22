
# Workload Identity Federation pool for GitHub Actions.
resource "google_iam_workload_identity_pool" "github_actions" {
  project                   = "floci-local"
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
  description               = "OIDC federation for the secure-gcp-foundation repository"
}

# Trust GitHub's official OIDC issuer, restricted to our repository.
resource "google_iam_workload_identity_pool_provider" "github_actions" {
  project                            = "floci-local"
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub Actions OIDC"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  attribute_condition = "assertion.sub == 'repo:zeeshan40132/secure-gcp-foundation:pull_request' || assertion.sub == 'repo:zeeshan40132/secure-gcp-foundation:ref:refs/heads/main'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}



# GitHub Actions can impersonate the plan service account.
# Repository restriction is enforced by the WIF provider condition.
resource "google_service_account_iam_member" "github_plan_workload_identity" {
  service_account_id = google_service_account.terraform_plan.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/zeeshan40132/secure-gcp-foundation"
}

# Only GitHub Actions running on the main branch can impersonate
# the apply service account.
resource "google_service_account_iam_member" "github_apply_workload_identity" {
  service_account_id = google_service_account.terraform_apply.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/zeeshan40132/secure-gcp-foundation"

  condition {
    title       = "main_branch_only"
    description = "Allow deployment only from the main branch"
    expression  = "attribute.ref == 'refs/heads/main'"
  }
}
