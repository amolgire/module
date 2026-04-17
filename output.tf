output "lb_names" {
  value = [for k, v in local.lb_map : v.full_name]
}