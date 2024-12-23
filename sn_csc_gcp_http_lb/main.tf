data "google_compute_network" "tfresource" {
  project = var.project
  name   = var.network
}

resource "google_compute_global_address" "default" {
  name         = "${var.url_map_name}-address"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "http" {
  count      = "${var.attach_vm ? 1 : 0}"
  name       = "${var.url_map_name}-http-rule"
  target     = google_compute_target_http_proxy.http[0].self_link
  ip_address = google_compute_global_address.default.address
  port_range = "80"
  depends_on = [google_compute_global_address.default]
}

resource "google_compute_global_forwarding_rule" "http_without_vm_instances" {
  count      = "${var.attach_vm ? 0 : 1}"
  name       = "${var.url_map_name}-http-rule"
  target     = google_compute_target_http_proxy.http_without_vm_instances[0].self_link
  ip_address = google_compute_global_address.default.address
  port_range = "80"
  depends_on = [google_compute_global_address.default]
}

resource "google_compute_target_http_proxy" "http" {
  count   = "${var.attach_vm ? 1 : 0}"
  name    = "${var.url_map_name}-http-proxy"
  url_map = google_compute_url_map.url_map[0].self_link
}

resource "google_compute_target_http_proxy" "http_without_vm_instances" {
  count   = "${var.attach_vm ? 0 : 1}"
  name    = "${var.url_map_name}-http-proxy"
  url_map = google_compute_url_map.url_map_without_vm_instances[0].self_link
}

resource "google_compute_backend_service" "backend_service" {
  count                   = "${var.attach_vm ? 1 : 0}"
  name                    = "${var.url_map_name}-back-end-service"
  protocol                = "HTTP"
  timeout_sec             = 30
  port_name               = "http"
  enable_cdn              = false
  health_checks = [google_compute_health_check.http_health_check.self_link]
  backend{
    group = google_compute_instance_group.lb_with_vm_instances[0].id
  }
}

resource "google_compute_backend_service" "backend_service_without_vm_instances" {
  count                   = "${var.attach_vm ? 0 : 1}"
  name                    = "${var.url_map_name}-back-end-service"
  protocol                = "HTTP"
  timeout_sec             = 30
  port_name               = "http"
  enable_cdn              = false
  health_checks = [google_compute_health_check.http_health_check.self_link]
  backend{
    group = google_compute_instance_group.lb_without_vm_instances[0].id
  }
}

resource "google_compute_url_map" "url_map" {
    count           = "${var.attach_vm ? 1 : 0}"
    name            = var.url_map_name
    default_service = google_compute_backend_service.backend_service[0].self_link
}

resource "google_compute_url_map" "url_map_without_vm_instances" {
    count           = "${var.attach_vm ? 0 : 1}"
    name            = var.url_map_name
    default_service = google_compute_backend_service.backend_service_without_vm_instances[0].self_link
}

resource "google_compute_health_check" "http_health_check" {
  name               = "${var.url_map_name}-http-health-check"
  check_interval_sec = 5
  timeout_sec        = 5
  http_health_check {
    port               = 80
    request_path       = "/"
    response            = "200"
  }
}

##CONFIGURING SINGLE IG with single VM

resource "google_compute_instance_group" "lb_with_vm_instances" {
  count       = "${var.attach_vm ? 1 : 0}"
  #instances must be in the same network and zone as the instance group
  instances   = var.lb_vm_instances
  name        = "${var.url_map_name}-with-vm-instances"
  network     = data.google_compute_network.tfresource.id
  zone        = var.lb_zone
  named_port {
    name = "http"
    port = "8080"
  }
  named_port {
    name = "https"
    port = "8443"
  }
}

resource "google_compute_instance_group" "lb_without_vm_instances" {
  count       = "${var.attach_vm ? 0 : 1}"
  #instances must be in the same network and zone as the instance group
  name        = "${var.url_map_name}-without-vm-instances"
  zone        = var.lb_zone
  network     = data.google_compute_network.tfresource.id
  named_port {
    name = "http"
    port = "8080"
  }
  named_port {
    name = "https"
    port = "8443"
  }
}