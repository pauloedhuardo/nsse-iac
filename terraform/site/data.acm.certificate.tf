data "aws_acm_certificate" "this" {
  domain   = var.domain
  statuses = ["ISSUED"]
}