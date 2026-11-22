# Regional Cloud Router for outbound connectivity.
resource "google_compute_router" "foundation_router" {
  name        = "secure-foundation-router"
  project     = "floci-local"
  region      = "us-central1"
  network     = google_compute_network.foundation_vpc.id
  description = "Cloud Router for private subnet Cloud NAT"

  bgp {
    asn = 64514
  }
}

# Cloud NAT provides outbound internet access to private instances.
resource "google_compute_router_nat" "foundation_nat" {
  name                               = "secure-foundation-nat"
  project                            = "floci-local"
  region                             = "us-central1"
  router                             = google_compute_router.foundation_router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private_subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
