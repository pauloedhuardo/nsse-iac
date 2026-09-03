resource "aws_s3_bucket" "site_logs" {
  bucket        = var.cloudfront.s3_site_logs_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "site_logs_versioning" {
  bucket = aws_s3_bucket.site_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}