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

data "google_compute_subnetwork" "subnetdata" {
  project = var.project
  region  = var.region
  name    = var.subnet_id
}

resource "google_compute_instance" "csc_basic_vm" {
  name           = var.vm_name
  machine_type   = var.machine_type
  zone           = var.zone
  desired_status = var.vm_desired_status

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

  metadata = var.authentication_type == "ssh_key" ? {
    ssh-keys       = "${var.ssh_user}:${var.ssh_pub_key}"
    enable-oslogin = "FALSE"
  } : {}
}

resource "google_compute_disk" "additional_disks" {
  for_each = { for idx, disk in var.additional_disks : idx => disk }

  name = "${var.vm_name}-disk-${each.key}"
  size = each.value["size_gb"]
  type = each.value["type"]
  image = data.google_compute_image.latest_image.self_link
  zone = var.zone
}