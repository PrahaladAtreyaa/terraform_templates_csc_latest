locals {
  image_map = {
    ubuntu : {
      project : "ubuntu-os-cloud"
      family : "ubuntu-2204-lts"
    },
    redhat : {
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
