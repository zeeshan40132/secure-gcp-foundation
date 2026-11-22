resource "google_compute_firewall" "insecure_public_ssh" {
  name      = "insecure-public-ssh"
  project   = "floci-local"
  network   = "secure-foundation-vpc"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
