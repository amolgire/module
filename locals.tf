locals {
  lb_map = {
    for lb in var.lbs :
    "${lb.name}" => merge(lb, {
      full_name = "${var.nar_id}-${var.environment}-${lb.name}"
    })
  }

  l4_lbs = {
    for k, v in local.lb_map : k => v if v.type == "L4"
  }

  l7_lbs = {
    for k, v in local.lb_map : k => v if v.type == "L7"
  }
}