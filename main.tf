module "ilb" {
  source = "../../modules/internal_lb"

  project_id = "my-project"
  nar_id     = "abc"
  environment = "dev"

  lbs = [
    {
      name       = "app-l7"
      type       = "L7"
      region     = "asia-south1"
      network    = "default"
      subnetwork = "default"

      protocol = "HTTP"
      ports    = ["80"]

      backend = {
        mig  = "instance-group-url"
        port = 80
      }

      health_check = {
        protocol = "HTTP"
        port     = 80
        path     = "/health"
      }
    },
    {
      name       = "db-l4"
      type       = "L4"
      region     = "asia-south1"
      network    = "default"
      subnetwork = "default"

      protocol = "TCP"
      ports    = ["5432"]

      backend = {
        neg  = "neg-url"
        port = 5432
      }

      health_check = {
        protocol = "TCP"
        port     = 5432
      }
    }
  ]
}