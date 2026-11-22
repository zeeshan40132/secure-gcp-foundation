resource "google_compute_firewall" "public_ssh" {
  name      = "public-ssh"
  network   = "example"
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}
