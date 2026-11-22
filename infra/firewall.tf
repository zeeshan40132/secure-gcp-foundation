# Deny all inbound traffic by default.
resource "google_compute_firewall" "deny_all_ingress" {
  name      = "secure-foundation-deny-ingress"
  project   = "floci-local"
  network   = google_compute_network.foundation_vpc.name
  direction = "INGRESS"
  priority  = 1000

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

# Permit SSH only through Identity-Aware Proxy.
resource "google_compute_firewall" "allow_iap_ssh" {
  name      = "secure-foundation-allow-iap-ssh"
  project   = "floci-local"
  network   = google_compute_network.foundation_vpc.name
  direction = "INGRESS"
  priority  = 900

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

# Permit internal communication within the private subnet.
resource "google_compute_firewall" "allow_internal" {
  name      = "secure-foundation-allow-internal"
  project   = "floci-local"
  network   = google_compute_network.foundation_vpc.name
  direction = "INGRESS"
  priority  = 800

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.10.0.0/24"]
}