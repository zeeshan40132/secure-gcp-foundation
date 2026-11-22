
resource "google_service_account_key" "bad_key" {
  service_account_id = "example"
}

resource "google_storage_bucket" "public_bucket" {
  name = "insecure-test-bucket"
}

resource "google_project_iam_member" "bad_role" {
  project = "example"
  role    = "roles/editor"
  member  = "allUsers"
}

resource "google_compute_firewall" "open_ssh" {
  name      = "open-ssh"
  network   = "default"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
