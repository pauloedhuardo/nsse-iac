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

variable "cloudfront" {
  type = object({
    s3_site_bucket_name              = string
    s3_site_logs_bucket_name         = string
    s3_staging_site_bucket_name      = string
    s3_staging_site_logs_bucket_name = string
    enabled                          = bool
    default_root_object              = string
    price_class                      = string
    alb_vpc_origin = object({
      name                   = string
      http_port              = number
      https_port             = number
      origin_protocol_policy = string
      origin_ssl_protocols = object({
        items    = list(string)
        quantity = number
      })
    })
    default_cache_behavior = object({
      allowed_methods        = list(string)
      cached_methods         = list(string)
      cache_policy_id        = string
      viewer_protocol_policy = string
    })
    ordered_cache_behavior = list(object({
      allowed_methods          = list(string)
      cached_methods           = list(string)
      cache_policy_id          = string
      origin_request_policy_id = string
      viewer_protocol_policy   = string
      path_pattern             = string
    }))
  })
  default = {
    s3_site_bucket_name              = "s2sinovatec.com"
    s3_site_logs_bucket_name         = "s2sinovatec.com-logs"
    s3_staging_site_bucket_name      = "staging.s2sinovatec.com"
    s3_staging_site_logs_bucket_name = "staging.s2sinovatec.com-logs"
    enabled                          = true
    default_root_object              = "index.html"
    price_class                      = "PriceClass_All"
    alb_vpc_origin = {
      name                   = "nsse-internal-vpc-origin"
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = {
        items    = ["TLSv1.2"]
        quantity = 1
      }
    }
    default_cache_behavior = {
      allowed_methods        = ["GET", "HEAD", "OPTIONS"]
      cached_methods         = ["GET", "HEAD"]
      cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
      viewer_protocol_policy = "redirect-to-https"
    }
    ordered_cache_behavior = [
      {
        allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
        cached_methods           = ["GET", "HEAD"]
        cache_policy_id          = "4cc15a8a-d715-48a4-82b8-cc0b614638fe" # UseOriginCacheControlHeaders-QueryStrings
        origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # Managed-AllViewer
        viewer_protocol_policy   = "redirect-to-https"
        path_pattern             = "/healthchecks/*"
      },
      {
        allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
        cached_methods           = ["GET", "HEAD"]
        cache_policy_id          = "4cc15a8a-d715-48a4-82b8-cc0b614638fe" # UseOriginCacheControlHeaders-QueryStrings
        origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # Managed-AllViewer
        viewer_protocol_policy   = "redirect-to-https"
        path_pattern             = "/identity/*"
      },
      {
        allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
        cached_methods           = ["GET", "HEAD"]
        cache_policy_id          = "4cc15a8a-d715-48a4-82b8-cc0b614638fe" # UseOriginCacheControlHeaders-QueryStrings
        origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # Managed-AllViewer
        viewer_protocol_policy   = "redirect-to-https"
        path_pattern             = "/main/*"
      },
      {
        allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
        cached_methods           = ["GET", "HEAD"]
        cache_policy_id          = "4cc15a8a-d715-48a4-82b8-cc0b614638fe" # UseOriginCacheControlHeaders-QueryStrings
        origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # Managed-AllViewer
        viewer_protocol_policy   = "redirect-to-https"
        path_pattern             = "/order/*"
      },
      {
        allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
        cached_methods           = ["GET", "HEAD"]
        cache_policy_id          = "4cc15a8a-d715-48a4-82b8-cc0b614638fe" # UseOriginCacheControlHeaders-QueryStrings
        origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # Managed-AllViewer
        viewer_protocol_policy   = "redirect-to-https"
        path_pattern             = "/invoice/*"
      },
      {
        allowed_methods          = ["GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
        cached_methods           = ["GET", "HEAD"]
        cache_policy_id          = "4cc15a8a-d715-48a4-82b8-cc0b614638fe" # UseOriginCacheControlHeaders-QueryStrings
        origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # Managed-AllViewer
        viewer_protocol_policy   = "redirect-to-https"
        path_pattern             = "/notificator/*"
      }
    ]
  }
}

variable "domain" {
  type = string

  default = "s2sinovatec.com"
}

# A API do CloudFront nao aceita ContinuousDeploymentPolicyId no CreateDistribution,
# apenas no UpdateDistribution. Mantenha false no apply que cria a distribuicao de
# producao e troque para true em um segundo apply para anexar a policy.
variable "attach_continuous_deployment_policy" {
  type    = bool
  default = false
}

variable "waf_webacl" {
  type = object({
    name  = string
    scope = string
    custom_response_body = object({
      key          = string
      message      = string
      content_type = string
    })
    visibility_config = object({
      cloudwatch_metrics_enabled = bool
      metric_name                = string
      sampled_requests_enabled   = bool
    })
  })

  default = {
    name  = "waf-s2sinovatec-webacl"
    scope = "CLOUDFRONT"
    custom_response_body = {
      key          = "403-CustomForbiddenResponse"
      message      = "You are not allowed to perform the action you requested."
      content_type = "APPLICATION_JSON"
    }
    visibility_config = {
      cloudwatch_metrics_enabled = false
      metric_name                = "waf-s2sinovatec-webacl-metrics"
      sampled_requests_enabled   = true
    }
  }

}