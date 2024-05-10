# #upload index.html to bucket 

# # resource "google_compute_instance" "my_instance" {
# #     name = "terraform-instance"
# #     machine_type = "f1-micro"
# #     zone = "us-central1-a"
# # }
resource "google_compute_network" "vpc_network" {
  name = "my-network"
  auto_create_subnetworks = true
  mtu = 1460
}
resource "google_compute_global_address" "default" {
  name = "static-ip"
}
# resource "google_compute_subnetwork" "vpc_subnetwork" {
#   name = "my-subnet"
#   ip_cidr_range = "10.0.0.0/24"
#   region = "us-central1"
#   purpose = "REGIONAL_MANAGED_PROXY"
#   role = "ACTIVE"
#   network = google_compute_network.vpc_network.id
# }
resource "google_compute_global_forwarding_rule" "default" {
  name = "forwarding-rules"
  ip_protocol = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range = "80"
  target = google_compute_target_http_proxy.default.id
  ip_address = google_compute_global_address.default.id
}
# HTTP target proxy
resource "google_compute_target_http_proxy" "default" {
  name     = "target-http-proxy"
  url_map  = google_compute_url_map.default.id
  
}

# URL map
resource "google_compute_url_map" "default" {
  name            = "url-map"
  default_service = google_compute_backend_service.default.id
}
# backend service
resource "google_compute_backend_service" "default" {
  name                     = "mybackendservice"
  protocol                 = "HTTP"
  port_name                = "http"
  load_balancing_scheme    = "EXTERNAL"
  timeout_sec              = 10
  enable_cdn               = true
  # custom_request_headers   = ["X-Client-Geo-Location: {client_region_subdivision}, {client_city}"]
  # custom_response_headers  = ["X-Cache-Hit: {cdn_cache_status}"]
  health_checks            = [google_compute_health_check.default.id]
  backend {
    group           = google_compute_instance_group_manager.instance-apache-group.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_instance_template" "instance_template1" {
    name = "apache-template"
    description = "Template used to create app server instances"
    
    tags = ["default-allow-ssh","http-server", "https-server", "allow-health-check"]

    machine_type = "f1-micro"    
    disk {
      source_image = "debian-cloud/debian-12"
      auto_delete = true
      boot = true 
    }
    metadata_startup_script = file("apachewebserver.sh")
    
    network_interface { 
     network = "default"
      access_config {
        // Ephemeral public IP
      }
    }
}

resource "google_compute_health_check" "default" {
  name                = "autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    request_path = "/healthz"
    port_specification = "USE_SERVING_PORT"
  }
}

resource "google_compute_instance_group_manager" "instance-apache-group" {
  name        = "terraform-test"
  base_instance_name = "app"
  # description = "Terraform test instance group of 3 "

  zone        = "us-central1-a"
  version {
    instance_template = google_compute_instance_template.instance_template1.self_link
  }
  target_size = 3

  named_port {
    name = "http"
    port = "8080"
  }
  named_port {
    name = "ssh"
    port = "22"
  }
  auto_healing_policies {
    health_check = google_compute_health_check.default.id
    initial_delay_sec = 300
  }
  instance_lifecycle_policy {
    force_update_on_repair    = "YES"
    default_action_on_failure = "DO_NOTHING"
}
}

resource "google_compute_firewall" "default" {
  name          = "allow-healthchecks"
  direction     = "INGRESS"
  network       = google_compute_network.vpc_network.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check"]
}