resource "google_compute_subnetwork" "private_subnet" {
  name          = "secure-foundation-private-subnet"
  project       = "floci-local"
  region        = "us-central1"
  network       = google_compute_network.foundation_vpc.id
  ip_cidr_range = "10.10.0.0/24"


  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
