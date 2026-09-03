variable "region" {
  type    = string
  default = "us-east-1"
}

variable "assume_role" {
  type = object({
    role_arn    = string
    external_id = string
  })

  default = {
    role_arn    = "arn:aws:iam::495624154773:role/terraform-role"
    external_id = "dc584012-b106-4605-9973-189dc02048c2"
  }
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "not-so-simple-ecommerce"
    Environment = "production"
  }
}

variable "remote_backend" {
  type = object({
    bucket = string
  })
  default = {
    bucket = "nsse-terraform-state-files-495624154773"
  }
}

variable "domain" {
  type = string

  default = "s2sinovatec.com"
}