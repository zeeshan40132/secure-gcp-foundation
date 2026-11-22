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