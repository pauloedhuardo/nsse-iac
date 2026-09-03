variable "region" {
  type    = string
  default = "us-east-1"

}

variable "tags" {
  type = object({
    Project     = string
    Environment = string
  })

  default = {
    Project     = "nsse"
    Environment = "production"
  }

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

variable "vpc" {

  type = object({
    name = string
  })

  default = {
    name = "nsse-production-vpc-p"
  }
}

variable "queues" {
  type = list(object({
    name                      = string
    delay_seconds             = number
    max_message_size          = number
    message_retention_seconds = number
    receive_wait_time_seconds = number
    sqs_managed_sse_enabled   = bool
  }))

  default = [
    {
      name                      = "EmailNotificationQueue"
      delay_seconds             = 0
      max_message_size          = 2048
      message_retention_seconds = 86400
      receive_wait_time_seconds = 10
      sqs_managed_sse_enabled   = true
    },
    {
      name                      = "ProductStockQueue"
      delay_seconds             = 0
      max_message_size          = 2048
      message_retention_seconds = 86400
      receive_wait_time_seconds = 10
      sqs_managed_sse_enabled   = true
    },
    {
      name                      = "InvoiceQueue"
      delay_seconds             = 0
      max_message_size          = 2048
      message_retention_seconds = 86400
      receive_wait_time_seconds = 10
      sqs_managed_sse_enabled   = true
    }
  ]
}

variable "dl_queues" {
  type = list(object({
    name                      = string
    delay_seconds             = number
    max_message_size          = number
    message_retention_seconds = number
    receive_wait_time_seconds = number
    sqs_managed_sse_enabled   = bool
  }))

  default = [
    {
      name                      = "EmailNotificationQueueDlq"
      delay_seconds             = 0
      max_message_size          = 2048
      message_retention_seconds = 86400
      receive_wait_time_seconds = 10
      sqs_managed_sse_enabled   = true
    },
    {
      name                      = "ProductStockQueueDlq"
      delay_seconds             = 0
      max_message_size          = 2048
      message_retention_seconds = 86400
      receive_wait_time_seconds = 10
      sqs_managed_sse_enabled   = true
    },
    {
      name                      = "InvoiceQueueDlq"
      delay_seconds             = 0
      max_message_size          = 2048
      message_retention_seconds = 86400
      receive_wait_time_seconds = 10
      sqs_managed_sse_enabled   = true
    }
  ]
}

variable "order_confirmed_topic" {
  type = object({
    name                             = string
    role_name                        = string
    sqs_success_feedback_sample_rate = number
    subscriptions                    = list(string)
  })

  default = {
    name                             = "OrderConfirmedTopic"
    role_name                        = "SnsTopicRole"
    sqs_success_feedback_sample_rate = 100
    subscriptions                    = ["InvoiceQueue", "ProductStockQueue"]
  }
}

variable "s3_application_bucket_name" {
  type    = string
  default = "nsse-application-495624154773"
}

variable "rds_aurora_cluster" {
  type = object({
    cluster_identifier           = string
    engine                       = string
    engine_mode                  = string
    database_name                = string
    master_username              = string
    manage_master_user_password  = bool
    availability_zones           = list(string)
    storage_encrypted            = bool
    final_snapshot_identifier    = string
    deletion_protection          = bool
    preferred_maintenance_window = string

    instances = list(object({
      instance_class    = string
      identifier        = string
      availability_zone = string
    }))

    serverlessv2_scaling_configuration = object({
      max_capacity = number
      min_capacity = number
    })
  })

  default = {
    cluster_identifier           = "nsse-aurora-serverless-cluster"
    engine                       = "aurora-postgresql"
    engine_mode                  = "provisioned"
    database_name                = "notSoSimpleEcommerce"
    master_username              = "nsseAdmin"
    manage_master_user_password  = true
    availability_zones           = ["us-east-1a", "us-east-1b"]
    storage_encrypted            = true
    final_snapshot_identifier    = "nsse-aurora-serverless-cluster-final-snapshot"
    deletion_protection          = true
    preferred_maintenance_window = "sun:05:00-sun:06:00"

    instances = [
      {
        instance_class    = "db.serverless"
        identifier        = "nsse-instance-us-east-1a"
        availability_zone = "us-east-1a"
      },
      {
        instance_class    = "db.serverless"
        identifier        = "nsse-instance-us-east-1b"
        availability_zone = "us-east-1b"
      }
    ]

    serverlessv2_scaling_configuration = {
      max_capacity = 1.0
      min_capacity = 0.5
    }
  }
}

variable "rds_proxy" {
  type = object({
    name = string
    read_only_endpoint = object({
      name        = string
      target_role = string
    })
    debug_logging       = bool
    engine_family       = string
    idle_client_timeout = number
    require_tls         = bool
    role_name           = string
    policy_name         = string
    auth = object({
      auth_scheme = string
      iam_auth    = string
    })
  })

  default = {
    name = "nsse-aurora-serverless-cluster-proxy"
    read_only_endpoint = {
      name        = "nsse-aurora-serverless-cluster-proxy-readonly"
      target_role = "READ_ONLY"
    }
    debug_logging       = false
    engine_family       = "POSTGRESQL"
    idle_client_timeout = 300
    require_tls         = true
    role_name           = "nsse-production-rds-proxy-role"
    policy_name         = "nsse-production-rds-proxy-policy"
    auth = {
      auth_scheme = "SECRETS"
      iam_auth    = "DISABLED"
    }
  }
}

variable "lambda_order_confirmed" {
  type = object({
    package_type  = string
    source_dir    = string
    output_path   = string
    filename      = string
    function_name = string
    handler       = string
    runtime       = string
    role_name     = string
    policy_name   = string
  })

  default = {
    package_type  = "zip"
    source_dir    = "lambdas/order-confirmed/build"
    output_path   = "lambdas/order-confirmed/outputs/package.zip"
    filename      = "lambdas/order-confirmed/outputs/package.zip"
    function_name = "OrderConfirmedLambdaFunction"
    handler       = "index.handler"
    runtime       = "nodejs24.x"
    role_name     = "nsse-production-order-confirmed-lambda-role"
    policy_name   = "nsse-production-order-confirmed-lambda-policy"
  }
}

variable "lambda_report_job" {
  type = object({
    timeout       = number
    package_type  = string
    source_dir    = string
    output_path   = string
    filename      = string
    function_name = string
    handler       = string
    runtime       = string
    role_name     = string
    policy_name   = string
  })

  default = {
    timeout       = 30
    package_type  = "zip"
    source_dir    = "lambdas/report-job/build"
    output_path   = "lambdas/report-job/outputs/package.zip"
    filename      = "lambdas/report-job/outputs/package.zip"
    function_name = "reportJobLambdaFunction"
    handler       = "index.handler"
    runtime       = "nodejs24.x"
    role_name     = "nsse-production-report-job-lambda-role"
    policy_name   = "nsse-production-report-job-lambda-policy"
  }
}

variable "lambda_layer_node_modules" {
  type = object({
    package_type        = string
    source_dir          = string
    output_path         = string
    filename            = string
    layer_name          = string
    compatible_runtimes = list(string)
  })

  default = {
    package_type        = "zip"
    source_dir          = "lambdas/layers/dependencies"
    output_path         = "lambdas/order-confirmed/outputs/node_modules_layer.zip"
    filename            = "lambdas/order-confirmed/outputs/node_modules_layer.zip"
    layer_name          = "node_modules"
    compatible_runtimes = ["nodejs24.x"]
  }
}

variable "security_groups" {
  type = object({
    control_plane = string
    worker        = string
    rds           = string
    documentdb    = string
  })

  default = {
    control_plane = "nsse-production-control-plane-security-group"
    worker        = "nsse-production-worker-security-group"
    rds           = "nsse-production-rds-security-group"
    documentdb    = "nsse-production-documentdb-security-group"
  }

}

variable "subnet_group" {
  type = object({
    db         = string
    documentdb = string
  })
  default = {
    db         = "nsse-production-db-subnet-group"
    documentdb = "nsse-production-documentdb-subnet-group"
  }
}

variable "domain" {
  type = string

  default = "s2sinovatec.com"
}

variable "documentdb_cluster" {
  type = object({
    cluster_identifier              = string
    database_name                   = string
    s3_certificate_path             = string
    engine                          = string
    master_username                 = string
    backup_retention_period         = number
    preferred_backup_window         = string
    preferred_maintenance_window    = string
    final_snapshot_identifier       = string
    storage_encrypted               = bool
    enabled_cloudwatch_logs_exports = list(string)
    availability_zones              = list(string)
    parameter_group = object({
      name   = string
      family = string
    })
    instance = object({
      identifier = string
      class      = string
    })
  })

  default = {
    cluster_identifier              = "nsse-documentdb-cluster"
    database_name                   = "notSoSimpleEcommerce"
    s3_certificate_path             = "app/documentedb-ca.pem"
    engine                          = "docdb"
    master_username                 = "nsse"
    backup_retention_period         = 7
    preferred_backup_window         = "01:00-02:00"
    preferred_maintenance_window    = "sun:03:00-sun:04:00"
    final_snapshot_identifier       = "nsse-document-cluster-final-snapshot"
    storage_encrypted               = true
    enabled_cloudwatch_logs_exports = ["audit", "profiler"]
    availability_zones              = ["us-east-1a", "us-east-1b"]
    parameter_group = {
      name   = "nsse-documentdb-parameter-group"
      family = "docdb5.0"
    }
    instance = {
      identifier = "nsse-documentdb-cluster-instance"
      class      = "db.t3.medium"
    }
  }
}

variable "event_bridge_scheduler_lambda_report_job" {
  type = object({
    schedule_name                 = string
    schedule_group_name           = string
    schedule_flexible_time_window = string
    schedule_expression           = string
    role_name                     = string
    policy_name                   = string
  })

  default = {
    schedule_name                 = "lambda-report-schedule"
    schedule_group_name           = "default"
    schedule_flexible_time_window = "OFF"
    schedule_expression           = "rate(1 minutes)"
    role_name                     = "nsse-production-event-bridge-scheduler-role"
    policy_name                   = "nsse-production-invoke-lambda-policy"
  }
}