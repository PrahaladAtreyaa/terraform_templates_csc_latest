locals {
  image_map = {
    ubuntu : {
      project : "ubuntu-os-cloud"
      family : "ubuntu-2204-lts"
    },
    centos : {
      project : "centos-cloud"
      family : "centos-stream-9"
    }
  }
}

data "google_compute_image" "latest_image" {
  project = local.image_map[var.image].project
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
  name   = var.network
}

data "google_compute_subnetwork" "subnetdata" {
  project = var.project
  region  = var.region
  name    = var.subnet
}

resource "google_compute_firewall" "ssh_rule" {
  count   = "${!var.isAdvancedNetwork && var.ssh ? 1 : 0}"
  name    = "${var.firewall_rule_name}-firewall-ssh"
  network = var.network
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = ["ssh-server"]
  source_ranges = split("," , var.allow_source_ranges)
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

resource "google_compute_instance" "csc_basic_vm" {
  
  name                = var.vm_name
  machine_type        = var.machine_type
  zone                = var.zone
  desired_status      = var.vm_desired_status
  hostname            = var.hostname

  boot_disk {
    device_name = "${var.vm_name}-disk"
    auto_delete = var.auto_delete
    mode        = "READ_WRITE"

    initialize_params {
      image = data.google_compute_image.latest_image.self_link
    }
  }

  network_interface {
    network    = var.network
    subnetwork = data.google_compute_subnetwork.subnetdata.name

    access_config {
      // Ephemeral public IP
    }
  }

  tags = local.basic_firewall_rules

  metadata = var.authentication_type == "ssh_key" ? {
    ssh-keys       = "${var.ssh_user}:${var.ssh_pub_key}"
    enable-oslogin = "FALSE"
  } : {}

  metadata_startup_script = var.authentication_type == "ssh_key" ? "" : <<EOT
    #!/bin/bash
    # Set up a new user with a password
    useradd -m -s /bin/bash "${var.vm_username}"
    echo "${var.vm_username}:${var.vm_password}" | chpasswd
    usermod -aG sudo "${var.vm_username}"
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart ssh
  EOT

}