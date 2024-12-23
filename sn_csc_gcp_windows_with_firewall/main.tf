locals {
  image_project = "windows-cloud"
  image_map = {
    "2022full" = {
      family : "windows-2022"
    },
    "2022core" : {
      family : "windows-2022-core"
    },
    "2019full" : {
      family : "windows-2019"
    },
    "2019core" : {
      family : "windows-2019-core"
    }
  }
}

data "google_compute_image" "latest_image" {
  project = local.image_project
  family  = local.image_map[var.image].family
}

locals {
  basic_firewall_rules_0 = []
  basic_firewall_rules_1 = !var.isAdvancedNetwork && var.http ? concat(local.basic_firewall_rules_0, ["http-server"]) : local.basic_firewall_rules_0
  basic_firewall_rules_2 = !var.isAdvancedNetwork && var.https ? concat(local.basic_firewall_rules_1, ["https-server"]) : local.basic_firewall_rules_1
  basic_firewall_rules_3 = !var.isAdvancedNetwork && var.ssh ? concat(local.basic_firewall_rules_2, ["ssh-server"]) : local.basic_firewall_rules_2
  basic_firewall_rules_4 = !var.isAdvancedNetwork && var.lb_health_check ? concat(local.basic_firewall_rules_3, ["lb-health-check"]) : local.basic_firewall_rules_3
  basic_firewall_rules_5 = var.isAdvancedNetwork && var.createNewNetworkFirewallRule ? concat(local.basic_firewall_rules_4, ["${var.vm_name}-custom-firewall-server"]) : local.basic_firewall_rules_4
  basic_firewall_rules = var.isAdvancedNetwork && !var.createNewNetworkFirewallRule ? concat(local.basic_firewall_rules_5, jsondecode(var.advanced_network_tag)) : local.basic_firewall_rules_5
}

data "google_compute_network" "tfresource" {
  project = var.project
  name    = var.network
}

data "google_compute_subnetwork" "subnetdata" {
  project = var.project
  region  = var.region
  name    = var.subnet
}

resource "google_compute_firewall" "http_rule" {
  count     = "${!var.isAdvancedNetwork && var.http ? 1 : 0}"
  name      = "${var.firewall_rule_name}-firewall-http"
  network   = var.network
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  target_tags   = ["http-server"]
  source_ranges = split("," , var.allow_source_ranges)
}

resource "google_compute_firewall" "https_rule" {
  count   = "${!var.isAdvancedNetwork && var.https ? 1 : 0}"
  name    = "${var.firewall_rule_name}-firewall-https"
  network = var.network
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
  target_tags   = ["https-server"]
  source_ranges = split("," , var.allow_source_ranges)
}

resource "google_compute_firewall" "custom_all_protcols" {
  count     = "${var.isAdvancedNetwork && var.createNewNetworkFirewallRule && var.all_protcols ? 1 : 0}"
  name      = "${var.firewall_rule_name}-custom-firewall-all"
  network   = data.google_compute_network.tfresource.name
  direction = var.traffic_direction
  priority  = var.priority
  allow {
    protocol = "all"
  }
  source_ranges = split("," , var.allow_source_ranges)
  target_tags   = ["${var.vm_name}-custom-firewall-server"]
}

resource "google_compute_firewall" "custom_any" {
  count    = "${var.isAdvancedNetwork && var.createNewNetworkFirewallRule && !var.all_protcols ? 1 : 0}"
  name     = "${var.firewall_rule_name}-custom-firewall"
  network  = data.google_compute_network.tfresource.name
  direction = var.traffic_direction
  priority = var.priority
  dynamic "allow" {
      for_each    = var.allowed_any_type_traffic
      content {
         protocol = allow.value.allowed_protocol
         ports = allow.value.allowed_ports == "" ? [] : split("," , allow.value.allowed_ports)
      }
  }
  source_ranges = split("," , var.allow_source_ranges)
  target_tags   = ["${var.vm_name}-custom-firewall-server"]
}

resource "google_compute_instance" "csc_basic_windows_vm" {
  
  name           = var.vm_name
  machine_type   = var.machine_type
  zone           = var.zone
  hostname       = var.hostname

  boot_disk {
    device_name = "${var.vm_name}-disk"
    auto_delete = var.auto_delete
    mode        = "READ_WRITE"

    initialize_params {
      image = data.google_compute_image.latest_image.self_link
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnetdata.name

    access_config {
      // Ephemeral public IP
    }
  }

  tags = local.basic_firewall_rules

  metadata = {
    enable-oslogin = "FALSE"
    sysprep-specialize-script-cmd ="net user ${var.vm_username} ${var.vm_password} /add & net localgroup administrators ${var.vm_username} /add"
  }

}

locals {
  parsedCredentials = jsondecode(var.credentials)
  wait_time = (var.machine_type == "e2-micro" || var.machine_type == "f1-micro" || var.machine_type == "g1-small")  ? "900s" : "300s"
}

data "google_service_account_access_token" "default" {
  provider               = google
  target_service_account = local.parsedCredentials.client_email
  scopes                 = ["cloud-platform"]
  lifetime               = "1800s"
}


resource "time_sleep" "sleep_time" {
  depends_on = [google_compute_instance.csc_basic_windows_vm]
  create_duration = local.wait_time
}

resource "null_resource" "null_resource_reset_metadata" {
  depends_on = [ time_sleep.sleep_time ]

  # Execute a local-exec provisioner to make the REST API call to remove custom meta data from VM
  provisioner "local-exec" {
    on_failure = continue
    command = <<EOF
      curl -X POST \
        -H "Authorization: Bearer ${data.google_service_account_access_token.default.access_token}" \
        -H "Content-Type: application/json" \
        -d '{"fingerprint": "${google_compute_instance.csc_basic_windows_vm.metadata_fingerprint}"}' \
        https://compute.googleapis.com/compute/v1/projects/${var.project}/zones/${var.zone}/instances/${var.vm_name}/setMetadata
    EOF
  }
}

