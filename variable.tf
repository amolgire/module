variable "project_id" {
  type = string
}

variable "nar_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "lbs" {
  description = "List of Load Balancers"
  type = list(object({
    name       = string
    type       = string # L4 or L7
    region     = string
    network    = string
    subnetwork = string

    protocol   = string # TCP / UDP / HTTP / HTTPS
    ports      = list(string)

    backend = object({
      mig  = optional(string)
      neg  = optional(string)
      port = number
    })

    health_check = object({
      protocol = string
      port     = number
      path     = optional(string)
    })

    ssl = optional(object({
      enable         = bool
      certificate_id = optional(string)
    }))
  }))
}