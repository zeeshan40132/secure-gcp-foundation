# Dedicated identity for Terraform plan operations.
resource "google_service_account" "terraform_plan" {
  account_id   = "sa-tf-plan"
  display_name = "Terraform Plan Service Account"
  project      = "floci-local"
  description  = "Read-only identity for Terraform plan operations"
}

# Dedicated identity for Terraform apply operations.
resource "google_service_account" "terraform_apply" {
  account_id   = "sa-tf-apply"
  display_name = "Terraform Apply Service Account"
  project      = "floci-local"
  description  = "Scoped deployment identity for Terraform apply operations"
}

# Read-only custom role for Terraform plan operations.
resource "google_project_iam_custom_role" "terraform_plan_role" {
  role_id     = "terraformPlan"
  title       = "Terraform Plan Role"
  description = "Read-only access to inspect foundation infrastructure"
  project     = "floci-local"

  permissions = [
    "resourcemanager.projects.get",
    "compute.networks.get",
    "compute.networks.list",
    "compute.subnetworks.get",
    "compute.subnetworks.list",
    "compute.firewalls.get",
    "compute.firewalls.list",
    "compute.routers.get",
    "compute.routers.list",
    "storage.buckets.get",
    "storage.buckets.list",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.list",
    "iam.roles.get",
    "iam.roles.list",
    "secretmanager.secrets.get",
    "secretmanager.secrets.list",
  ]
}

# Scoped deployment role for Terraform apply operations.
resource "google_project_iam_custom_role" "terraform_apply_role" {
  role_id     = "terraformApply"
  title       = "Terraform Apply Role"
  description = "Manage only the resource types used by the secure foundation"
  project     = "floci-local"

  permissions = [
    "resourcemanager.projects.get",
    "compute.networks.get",
    "compute.networks.list",
    "compute.networks.create",
    "compute.networks.update",
    "compute.networks.delete",
    "compute.subnetworks.get",
    "compute.subnetworks.list",
    "compute.subnetworks.create",
    "compute.subnetworks.update",
    "compute.subnetworks.delete",
    "compute.firewalls.get",
    "compute.firewalls.list",
    "compute.firewalls.create",
    "compute.firewalls.update",
    "compute.firewalls.delete",
    "compute.routers.get",
    "compute.routers.list",
    "compute.routers.create",
    "compute.routers.update",
    "compute.routers.delete",
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.buckets.create",
    "storage.buckets.update",
    "storage.buckets.delete",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.create",
    "iam.serviceAccounts.update",
    "iam.serviceAccounts.delete",
    "iam.roles.get",
    "iam.roles.list",
    "secretmanager.secrets.get",
    "secretmanager.secrets.list",
    "secretmanager.secrets.create",
    "secretmanager.secrets.update",
    "secretmanager.secrets.delete",
  ]
}

# Grant the read-only custom role to the Terraform plan identity.
resource "google_project_iam_member" "terraform_plan_binding" {
  project = "floci-local"
  role    = google_project_iam_custom_role.terraform_plan_role.name
  member  = google_service_account.terraform_plan.member
}

# Grant the scoped deployment role to the Terraform apply identity.
resource "google_project_iam_member" "terraform_apply_binding" {
  project = "floci-local"
  role    = google_project_iam_custom_role.terraform_apply_role.name
  member  = google_service_account.terraform_apply.member
}

# Allow the application identity to access only its designated secret.
resource "google_secret_manager_secret_iam_member" "app_secret_accessor" {
  project   = "floci-local"
  secret_id = google_secret_manager_secret.app_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = google_service_account.app_service_account.member
}
