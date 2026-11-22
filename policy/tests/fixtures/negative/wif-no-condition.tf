resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = "example"
  workload_identity_pool_id          = "github-actions"
  workload_identity_pool_provider_id = "github"

  attribute_mapping = {
    "google.subject" = "assertion.sub"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}
