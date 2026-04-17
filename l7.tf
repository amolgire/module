resource "google_compute_health_check" "l7_hc" {
  for_each = local.l7_lbs

  name = "${each.value.full_name}-hc"

  http_health_check {
    port         = each.value.health_check.port
    request_path = lookup(each.value.health_check, "path", "/")
  }
}

resource "google_compute_backend_service" "l7_backend" {
  for_each = local.l7_lbs

  name                  = "${each.value.full_name}-backend"
  load_balancing_scheme = "INTERNAL_MANAGED"
  protocol              = each.value.protocol
  health_checks         = [google_compute_health_check.l7_hc[each.key].id]

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

resource "google_compute_url_map" "l7_urlmap" {
  for_each = local.l7_lbs

  name            = "${each.value.full_name}-urlmap"
  default_service = google_compute_backend_service.l7_backend[each.key].id
}

resource "google_compute_target_http_proxy" "http_proxy" {
  for_each = {
    for k, v in local.l7_lbs : k => v if v.protocol == "HTTP"
  }

  name    = "${each.value.full_name}-http-proxy"
  url_map = google_compute_url_map.l7_urlmap[each.key].id
}

resource "google_compute_target_https_proxy" "https_proxy" {
  for_each = {
    for k, v in local.l7_lbs : k => v if v.protocol == "HTTPS"
  }

  name             = "${each.value.full_name}-https-proxy"
  url_map          = google_compute_url_map.l7_urlmap[each.key].id
  ssl_certificates = [each.value.ssl.certificate_id]
}

resource "google_compute_forwarding_rule" "l7_ilb" {
  for_each = local.l7_lbs

  name                  = "${each.value.full_name}-fr"
  region                = each.value.region
  load_balancing_scheme = "INTERNAL_MANAGED"
  network               = each.value.network
  subnetwork            = each.value.subnetwork
  ports                 = each.value.ports

  target = coalesce(
    try(google_compute_target_https_proxy.https_proxy[each.key].id, null),
    google_compute_target_http_proxy.http_proxy[each.key].id
  )
}