variable "region" {
  type    = string
  default = "us-east-1"

}

variable "vpc" {

  type = object({
    name = string
  })

  default = {
    name = "nsse-production-vpc-p"
  }
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

variable "ec2_resources" {
  type = object({
    key_pair_name                = string
    instance_profile             = string
    instance_role                = string
    control_plane_security_group = string
    worker_security_group        = string
    alb_security_group           = string
  })

  default = {
    key_pair_name                = "nsse-production-key-pair"
    instance_profile             = "nsse-production-instance-profile"
    instance_role                = "nsse-production-instance-role"
    control_plane_security_group = "nsse-production-control-plane-security-group"
    worker_security_group        = "nsse-production-worker-security-group"
    alb_security_group           = "nsse-production-alb-security-group"
  }

}

variable "control_plane_launch_template" {
  type = object({
    name                                 = string
    disable_api_stop                     = bool
    disable_api_termination              = bool
    instance_type                        = string
    instance_initiated_shutdown_behavior = string
    user_data                            = string
    ebs = object({
      volume_size           = number
      delete_on_termination = bool
    })
  })

  default = {
    name                                 = "nsse-production-debian-control-plane-lt"
    disable_api_stop                     = true
    disable_api_termination              = true
    instance_type                        = "t3.medium"
    instance_initiated_shutdown_behavior = "terminate"
    user_data                            = "./cli/control-plane-user-data.sh"
    ebs = {
      volume_size           = 20
      delete_on_termination = false
    }
  }

}

variable "control_plane_auto_scaling_group" {
  type = object({
    name                      = string
    max_size                  = number
    min_size                  = number
    desired_capacity          = number
    health_check_grace_period = number
    health_check_type         = string
    instance_tags = object({
      Name = string
    })
    instance_maintenance_policy = object({
      min_healthy_percentage = number
      max_healthy_percentage = number
    })
  })

  default = {
    name                      = "nsse-production-control-plane-asg"
    max_size                  = 2
    min_size                  = 1
    desired_capacity          = 2
    health_check_grace_period = 180
    health_check_type         = "EC2"
    instance_tags = {
      Name = "nsse-production-control-plane"
    }
    instance_maintenance_policy = {
      min_healthy_percentage = 100
      max_healthy_percentage = 110
    }
  }

}

variable "worker_launch_template" {
  type = object({
    name                                 = string
    disable_api_stop                     = bool
    disable_api_termination              = bool
    instance_type                        = string
    instance_initiated_shutdown_behavior = string
    user_data                            = string
    ebs = object({
      volume_size           = number
      delete_on_termination = bool
    })
  })

  default = {
    name                                 = "nsse-production-debian-worker-lt"
    disable_api_stop                     = true
    disable_api_termination              = true
    instance_type                        = "t3.small"
    instance_initiated_shutdown_behavior = "terminate"
    user_data                            = "./cli/worker-user-data.sh"
    ebs = {
      volume_size           = 20
      delete_on_termination = false
    }
  }

}

variable "worker_auto_scaling_group" {
  type = object({
    name                           = string
    max_size                       = number
    min_size                       = number
    desired_capacity               = number
    health_check_grace_period      = number
    health_check_type              = string
    cluster_autoscaler_policy_name = string
    instance_tags = object({
      Name = string
    })
    instance_maintenance_policy = object({
      min_healthy_percentage = number
      max_healthy_percentage = number
    })
  })

  default = {
    name                           = "nsse-production-worker-asg"
    max_size                       = 5
    min_size                       = 1
    desired_capacity               = 4
    health_check_grace_period      = 180
    health_check_type              = "EC2"
    cluster_autoscaler_policy_name = "nsse-production-cluster-autoscaler-policy"
    instance_tags = {
      Name = "nsse-production-worker"
    }
    instance_maintenance_policy = {
      min_healthy_percentage = 100
      max_healthy_percentage = 110
    }
  }

}

variable "debian_patch_baseline" {
  type = object({
    name                                 = string
    description                          = string
    approved_patches_enable_non_security = bool
    operating_system                     = string
    approval_rules = list(object({
      approve_after_days = number
      compliance_level   = string
      patch_filter = object({
        product  = list(string)
        section  = list(string)
        priority = list(string)
      })
    }))
  })

  default = {
    name                                 = "DebianProductionPatchBaseline"
    description                          = "Custom Path Baseline for Debian Production Servers"
    approved_patches_enable_non_security = false
    operating_system                     = "DEBIAN"
    approval_rules = [{
      approve_after_days = 0
      compliance_level   = "CRITICAL"
      patch_filter = {
        product  = ["Debian13"]
        section  = ["*"]
        priority = ["Required", "Important"]
      }
      },
      {
        approve_after_days = 0
        compliance_level   = "INFORMATIONAL"
        patch_filter = {
          product  = ["Debian13"]
          section  = ["*"]
          priority = ["Standard"]
        }

      }
    ]
  }
}

variable "path_group" {
  type = string

  default = "Production"
}

variable "debian_production_association" {
  type = object({
    name                = string
    schedule_expression = string
    association_name    = string
    max_concurrency     = number
    max_errors          = number
    output_location = object({
      s3_key_prefix = string
    })
    parameters = object({
      Operation    = string
      RebootOption = string
    })
    targets_key = string
  })

  default = {
    name                = "AWS-RunPatchBaseline"
    schedule_expression = "cron(*/30 * * * ? *)"
    association_name    = "DebianRunPatchBaselineAssociation"
    max_concurrency     = 1
    max_errors          = 0
    output_location = {
      s3_key_prefix = "patching-logs"
    }
    parameters = {
      Operation    = "Install"
      RebootOption = "RebootIfNeeded"
    }
    targets_key = "tag:PatchGroup"
  }
}

variable "logs_bucket" {
  type = object({
    bucket_name   = string
    force_destroy = bool
  })

  default = {
    bucket_name   = "nsse-producion-logs"
    force_destroy = true
  }
}

variable "bucket_ssm" {
  type    = string
  default = "nsse-ansible-ssm-495624154773"
}

variable "network_load_balancer" {
  type = object({
    name               = string
    internal           = bool
    load_balancer_type = string
    listener = object({
      port     = string
      protocol = string
    })
    target_group = object({
      name               = string
      target_type        = string
      port               = number
      protocol           = string
      preserve_client_ip = bool
    })
  })

  default = {
    name               = "nsse-production-cp-nlb"
    internal           = true
    load_balancer_type = "network"
    listener = {
      port     = "6443"
      protocol = "TCP"
    }
    target_group = {
      name               = "nsse-production-cp-nlb-tcp-tg"
      target_type        = "instance"
      port               = 6443
      protocol           = "TCP"
      preserve_client_ip = false
    }
  }

}

variable "external_node_termination" {
  type = object({
    role_name   = string
    policy_name = string
    queue = object({
      name                      = string
      message_retention_seconds = number
      sqs_managed_sse_enabled   = bool
    })
    autoscaling_lifecycle_hook = object({
      name                 = string
      default_result       = string
      heartbeat_timeout    = number
      lifecycle_transition = string
    })
  })

  default = {
    role_name   = "nsse-production-node-termination-role"
    policy_name = "nsse-production-node-termination-policy"
    queue = {
      name                      = "NodeTerminationQueue"
      message_retention_seconds = 300
      sqs_managed_sse_enabled   = true
    }
    autoscaling_lifecycle_hook = {
      name                 = "NodeTerminationNotification"
      default_result       = "CONTINUE"
      heartbeat_timeout    = 300
      lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    }
  }
}

variable "external_cloud_controller_manager" {
  type = object({
    policy_name = string
  })

  default = {
    policy_name = "nsse-production-cloud-controller-manager"
  }
}

variable "ecr_pull" {
  type = object({
    policy_name = string
  })

  default = {
    policy_name = "nsse-production-ecr-pull"
  }
}

variable "external_aws_load_balancer_controller" {
  type = object({
    policy_name = string
  })

  default = {
    policy_name = "nsse-production-load-balancer-controller"
  }
}

variable "external_dns" {
  type = object({
    policy_name = string
  })

  default = {
    policy_name = "nsse-production-external-dns"
  }
}



variable "ecr_repositories" {
  type = list(object({
    name                 = string
    image_tag_mutability = string
  }))

  default = [
    {
      name                 = "nsse/production/health-checker"
      image_tag_mutability = "MUTABLE"
    },
    {
      name                 = "nsse/production/notificator"
      image_tag_mutability = "MUTABLE"
    },
    {
      name                 = "nsse/production/order"
      image_tag_mutability = "MUTABLE"
    },
    {
      name                 = "nsse/production/invoice-generator"
      image_tag_mutability = "MUTABLE"
    },
    {
      name                 = "nsse/production/main"
      image_tag_mutability = "MUTABLE"
    },
    {
      name                 = "nsse/production/identity-server"
      image_tag_mutability = "MUTABLE"
    },
  ]
}

variable "domain" {
  type = string

  default = "s2sinovatec.com"
}