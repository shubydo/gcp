resource "google_compute_network" "vpc" {
  name                    = "${local.common_prefix}-vpc"
  auto_create_subnetworks = false
  # delete_default_routes_on_create = false
}


# Allow SSH access to bastion agent
resource "google_compute_firewall" "allow_ssh" {
  name      = "allow-ssh-bastion-${local.common_prefix}"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "tcp"
    ports    = [22]
  }

  source_ranges = [local.client_ip]
  target_tags   = ["ssh-enabled"]

  # log_config {
  #   # metadata = 
  # }
  # Try if you can't get this to work
  # target_service_accounts = google_compute_instance.bastion_agents.service_accounts
}

resource "google_compute_firewall" "allow_traffic_from_iap" {
  name      = "allow-ssh-traffic-from-iap-${local.common_prefix}"
  network   = google_compute_network.vpc.name
  direction = "INGRESS"
  priority  = 777
  allow {
    protocol = "tcp"
    ports    = [22]
  }

  source_ranges = ["35.235.240.0/20"]
  # not specifying target_tags or SAs applies to all instances
  target_tags = ["ssh-enabled"]

  # log_config {
  #   # metadata = 
  # }
  # Try if you can't get this to work
  # target_service_accounts = google_compute_instance.bastion_agents.service_accounts
}



# Subnets for DB and build agents
resource "google_compute_subnetwork" "cloudsql" {
  name          = "${local.common_prefix}-cloudsql-subnet-${var.environment}-${var.region}"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}


resource "google_compute_router" "router" {
  name    = "${local.common_prefix}-router"
  region  = google_compute_subnetwork.cloudsql.region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "${local.common_prefix}-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }

}
