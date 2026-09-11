output "s3_site_bucket_domain" {
  value = aws_s3_bucket.site.bucket_regional_domain_name
}

output "s3_site_logs_bucket_domain" {
  value = aws_s3_bucket.site_logs.bucket_regional_domain_name
}

# Usado pelo destroy.sh para desanexar a continuous deployment policy via AWS CLI
# antes do destroy.
output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.this.id
}