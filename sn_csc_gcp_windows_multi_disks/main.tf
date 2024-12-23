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

data "google_compute_subnetwork" "subnetdata" {
  project = var.project
  region  = var.region
  name    = var.subnet_id
}

resource "google_compute_instance" "csc_basic_windows_vm" {
  name           = var.vm_name
  machine_type   = var.machine_type
  zone           = var.zone

  boot_disk {
    device_name = "${var.vm_name}-boot-disk"
    auto_delete = var.auto_delete
    mode        = "READ_WRITE"
    initialize_params {
      image = data.google_compute_image.latest_image.self_link
      size = var.boot_disk_size_gb
      type = var.boot_disk_type
    }
  }

  dynamic "attached_disk" {
    for_each = var.additional_disks
    content {
      source      = google_compute_disk.additional_disks[attached_disk.key].self_link
      device_name = attached_disk.key
      mode        = "READ_WRITE"
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.subnetdata.name

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "FALSE"
    sysprep-specialize-script-cmd ="net user ${var.vm_username} ${var.vm_password} /add & net localgroup administrators ${var.vm_username} /add"
  }
}

resource "google_compute_disk" "additional_disks" {
  for_each = { for idx, disk in var.additional_disks : idx => disk }

  name = "${var.vm_name}-disk-${each.key}"
  size = each.value["size_gb"]
  type = each.value["type"]
  image = data.google_compute_image.latest_image.self_link
  zone = var.zone
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