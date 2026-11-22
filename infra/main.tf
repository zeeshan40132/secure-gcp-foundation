locals {
  common_labels = {
    env         = "dev"
    owner       = "devops-lab"
    cost-center = "engineering"
  }
}

# 1. Private Cloud Storage bucket
resource "google_storage_bucket" "foundation_bucket" {
  name          = "secure-foundation-artifacts-floci-local"
  location      = "US"
  project       = "floci-local"
  force_destroy = true
  versioning {
    enabled = true
  }

  logging {
    log_bucket        = google_storage_bucket.access_logs_bucket.name
    log_object_prefix = "foundation-bucket-access/"
  }

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  labels = local.common_labels
}

# 2. Dedicated application service account
resource "google_service_account" "app_service_account" {
  account_id   = "secure-foundation-app"
  display_name = "Secure Foundation Application"
  project      = "floci-local"
  description  = "Dedicated runtime identity for the demo application"
}

# 3. Secret Manager container (no secret value)
resource "google_secret_manager_secret" "app_secret" {
  secret_id = "secure-foundation-app-secret"
  project   = "floci-local"

  labels = local.common_labels

  replication {
    auto {}
  }
}


# Dedicated destination for Cloud Storage access logs.
resource "google_storage_bucket" "access_logs_bucket" {
  name          = "secure-foundation-access-logs-floci-local"
  location      = "US"
  project       = "floci-local"
  force_destroy = true

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  labels = local.common_labels

  # This bucket must not log to itself; that would create recursive logs.
  #checkov:skip=CKV_GCP_62:Dedicated access-log destination; self-logging would be recursive.
}