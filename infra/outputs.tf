output "bucket_name" {
  description = "Name of the private artifacts bucket"
  value       = google_storage_bucket.foundation_bucket.name
}

output "app_service_account_email" {
  description = "Email of the application service account"
  value       = google_service_account.app_service_account.email
}

output "secret_id" {
  description = "Secret Manager resource ID"
  value       = google_secret_manager_secret.app_secret.id
}



output "workload_identity_pool_name" {
  description = "Workload Identity Federation pool resource name"
  value       = google_iam_workload_identity_pool.github_actions.name
}

output "workload_identity_provider_name" {
  description = "GitHub Actions OIDC provider resource name"
  value       = google_iam_workload_identity_pool_provider.github_actions.name
}

output "terraform_plan_service_account" {
  description = "Service account used by GitHub Actions for Terraform plans"
  value       = google_service_account.terraform_plan.email
}

output "terraform_apply_service_account" {
  description = "Service account used by GitHub Actions for Terraform applies"
  value       = google_service_account.terraform_apply.email
}
