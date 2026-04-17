resource "google_compute_health_check" "l4_hc" {
  for_each = local.l4_lbs

  name    = "${each.value.full_name}-hc"
  project = var.project_id

  tcp_health_check {
    port = each.value.health_check.port
  }
}

resource "google_compute_region_backend_service" "l4_backend" {
  for_each = local.l4_lbs

  name                  = "${each.value.full_name}-backend"
  region                = each.value.region
  load_balancing_scheme = "INTERNAL"
  protocol              = each.value.protocol
  health_checks         = [google_compute_health_check.l4_hc[each.key].id]

  dynamic "backend" {
    for_each = each.value.backend.mig != null ? [1] : []
    content {
      group = each.value.backend.mig
    }
  }

  dynamic "backend" {
    for_each = each.value.backend.neg != null ? [1] : []
    content {
      group = each.value.backend.neg
    }
  }
}

resource "google_compute_forwarding_rule" "l4_ilb" {
  for_each = local.l4_lbs

  name                  = "${each.value.full_name}-fr"
  region                = each.value.region
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.l4_backend[each.key].id
  network               = each.value.network
  subnetwork            = each.value.subnetwork
  ports                 = each.value.ports
}