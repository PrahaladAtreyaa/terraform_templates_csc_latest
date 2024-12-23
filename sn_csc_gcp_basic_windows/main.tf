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