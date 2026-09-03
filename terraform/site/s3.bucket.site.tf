resource "aws_s3_bucket" "site" {
  bucket        = var.cloudfront.s3_site_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "site_versioning" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}