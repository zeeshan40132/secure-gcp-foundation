resource "google_compute_network" "foundation_vpc" {
  name                    = "secure-foundation-vpc"
  project                 = "floci-local"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "Custom VPC for the secure foundation project"
}