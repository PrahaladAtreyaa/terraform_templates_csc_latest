variable project {}
variable region {}
variable credentials {}
variable zone {}

variable hostname {}

variable vm_name {
  type = string
}

variable machine_type {
  type = string
}

variable auto_delete {
  type = bool
  default = true
}

variable image {
  type = string
}

variable network {
  type = string
}

variable subnet {
  type = string
}

variable vm_username {
  type    = string
}

variable vm_password {
  type    = string
}

variable firewall_rule_name {
  type    = string
  default = ""
}

variable ssh {
  type    = bool
  default = false
}

variable http {
  type    = bool
  default = false
}

variable https {
  type    = bool
  default = false
}

variable lb_health_check {
  type    = bool
  default = false
}

variable isAdvancedNetwork {
  type    = bool
  default = false
}

variable createNewNetworkFirewallRule {
  type    = bool
  default = true
}

variable all_protcols {
  type = bool
  default = false
}

variable priority {
  default = 1000
}

variable traffic_direction {
  type    = string
  default = "INGRESS"
}

variable allowed_any_type_traffic {
  type        = list(object({
    allowed_protocol      = string
    allowed_ports         = string
  }))
}

variable allow_source_ranges {
  type    = string
  default = ""
}

variable advanced_network_tag {
  default = []
}