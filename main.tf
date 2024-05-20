
resource "google_compute_network" "default" {
  name = "vpc-network-capstone"
  auto_create_subnetworks = false
}
# resource "google_compute_global_address" "default" {
#   name = "static-ip"
# }
resource "google_compute_subnetwork" "subnetwork" {
    name = "subnetwork"
    region = "us-central1"
    network = google_compute_network.default.id
    ip_cidr_range = "10.0.0.0/24"
}
resource "google_compute_firewall" "ssh-firewall" {
  name          = "allow-ssh-firewall-rule"
  network       = google_compute_network.default.id
  allow {
    protocol = "tcp"
    ports = ["22"]
  }
  target_tags = ["allow-ssh-firewall-rule"]
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_firewall" "allow-health-check" {
  name          = "allow-hc"
  direction     = "INGRESS"
  network       = google_compute_network.default.id
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
  }
  target_tags = ["allow-health-check"]
}

resource "google_compute_global_forwarding_rule" "default" {
  name = "forwarding-rules"
  port_range = "80"
  target = google_compute_target_http_proxy.default.id
  # ip_address = google_compute_global_address.default.id
}
# HTTP target proxy
resource "google_compute_target_http_proxy" "default" {
  name     = "target-http-proxy"
  url_map  = google_compute_url_map.default.id
  
}

# # URL map
resource "google_compute_url_map" "default" {
  name            = "url-map"
  default_service = google_compute_backend_service.default.id
}
# backend service
resource "google_compute_backend_service" "default" {
  name                     = "mybackendservice"
  protocol                 = "HTTP"
  port_name                = "http"
  # load_balancing_scheme    = "EXTERNAL"
  timeout_sec              = 10
  # custom_request_headers   = ["X-Client-Geo-Location: {client_region_subdivision}, {client_city}"]
  # custom_response_headers  = ["X-Cache-Hit: {cdn_cache_status}"]
  health_checks            = [google_compute_health_check.health-check.id]
  
  backend {
    group           = google_compute_instance_group_manager.instance-apache-group.instance_group
    # balancing_mode  = "UTILIZATION"
    # capacity_scaler = 1.0
  }
}

resource "google_compute_instance_template" "instance_template1" {
    name = "instance-template"
    description = "Template for running spring petclinic app"
    
    # tags = ["default-allow-ssh","http-server", "https-server", "allow-health-check"]

    machine_type = "e2-micro"    
    disk {
      source_image = "debian-cloud/debian-12"
      auto_delete = true
      boot = true 
    }
    metadata_startup_script = file("apachewebserver.sh")
    labels = {
      mig-label = "capstone-mig"
    }
    network_interface { 
     network = google_compute_network.default.self_link
     subnetwork = google_compute_subnetwork.subnetwork.id
      access_config {
        // Ephemeral public IP
      }
    }
    tags = ["allow-health-check", "allow-ssh-firewall-rule"]
}

resource "google_compute_health_check" "health-check" {
  name                = "myhealth-check"
  check_interval_sec  = 10
  timeout_sec         = 10
  
  http_health_check {
    request_path = "/"
    port = "80" 
  }
}
resource "google_compute_health_check" "tcp-health-check" {
  name                = "tcp-autohealing-health-check"
  check_interval_sec  = 5
  timeout_sec         = 5
  
  tcp_health_check {
    port = "80"
  }
}
resource "google_compute_instance_group_manager" "instance-apache-group" {
  name        = "terraform-test"
  base_instance_name = "instance"
  # description = "Terraform test instance group 2 "

  zone        = "us-central1-a"
  version {
    instance_template = google_compute_instance_template.instance_template1.id
    name = "primary"
  }
  target_size = 2

  named_port {
    name = "http"
    port = "80"
  }
#   auto_healing_policies {
#     health_check = google_compute_health_check.default.id
#     initial_delay_sec = 300
#   }
#   instance_lifecycle_policy {
#     force_update_on_repair    = "YES"
#     default_action_on_failure = "DO_NOTHING"
# }
}



# capstone notes
# to add additionally a container 
# gcloud compute instances update-container nginx-vm \
#     --container-image gcr.io/cloud-marketplace/google/nginx1:latest //nije od koristi

# gcloud compute instance-templates create-with-container TEMPLATE_NAME
#  \
#   --container-image DOCKER_IMAGE
# gcloud compute networks create vpc-capstone-katarina --project=gd-gcp-internship-devops --description=custom\ vpc\ for\ capstone\ project --subnet-mode=auto --mtu=1460 --bgp-routing-mode=regional

# gcloud compute firewall-rules create vpc-capstone-katarina-allow-icmp --project=gd-gcp-internship-devops --network=projects/gd-gcp-internship-devops/global/networks/vpc-capstone-katarina --description=Allows\ ICMP\ connections\ from\ any\ source\ to\ any\ instance\ on\ the\ network. --direction=INGRESS --priority=65534 --source-ranges=0.0.0.0/0 --action=ALLOW --rules=icmp

# gcloud compute firewall-rules create vpc-capstone-project-katarina-allow-custom --project=gd-gcp-internship-devops --network=projects/gd-gcp-internship-devops/global/networks/vpc-capstone-project-katarina --description=Allows\ connection\ from\ any\ source\ to\ any\ instance\ on\ the\ network\ using\ custom\ protocols. --direction=INGRESS --priority=65534 --source-ranges=10.128.0.0/9 --action=ALLOW --rules=tcp:80,tcp:443,tcp:8080-8082

# gcloud compute firewall-rules create vpc-capstone-katarina-allow-ssh --project=gd-gcp-internship-devops --network=projects/gd-gcp-internship-devops/global/networks/vpc-capstone-katarina --description=Allows\ TCP\ connections\ from\ any\ source\ to\ any\ instance\ on\ the\ network\ using\ port\ 22. --direction=INGRESS --priority=65534 --source-ranges=0.0.0.0/0 --action=ALLOW --rules=tcp:22

# gcloud beta compute instance-templates create instance-template-capstone --project=gd-gcp-internship-devops --machine-type=g1-small --network-interface=network=vpc-capstone-project-katarina,network-tier=PREMIUM --instance-template-region=us-central1 --maintenance-policy=MIGRATE --provisioning-model=STANDARD --service-account=71936227901-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --create-disk=auto-delete=yes,boot=yes,device-name=instance-template-capstone,image=projects/ubuntu-os-cloud/global/images/ubuntu-2204-jammy-v20240519,mode=rw,size=10,type=pd-balanced --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any

# gcloud beta compute health-checks create tcp health-check-capstone --project=gd-gcp-internship-devops --port=80 --proxy-header=NONE --no-enable-logging --check-interval=60 --timeout=30 --unhealthy-threshold=2 --healthy-threshold=2

# gcloud beta compute instance-groups managed create instance-group-capstone-katarina --project=gd-gcp-internship-devops --base-instance-name=instance-group-capstone-katarina --template=projects/gd-gcp-internship-devops/regions/us-central1/instanceTemplates/instance-template-capstone --size=1 --zone=us-central1-c --default-action-on-vm-failure=repair --health-check=projects/gd-gcp-internship-devops/global/healthChecks/health-check-capstone --initial-delay=300 --no-force-update-on-repair --standby-policy-mode=manual --list-managed-instances-results=PAGELESS

# gcloud beta compute instance-groups managed set-autoscaling instance-group-capstone-katarina --project=gd-gcp-internship-devops --zone=us-central1-c --mode=off --min-num-replicas=3 --max-num-replicas=3 --target-cpu-utilization=0.6 --cool-down-period=60