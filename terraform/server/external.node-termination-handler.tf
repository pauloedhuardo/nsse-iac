data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "node_termination_queue_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "autoscaling.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.external_node_termination.queue.name}"]
  }
}

data "aws_iam_policy_document" "node_termination_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_sqs_queue" "node_termination" {
  name                      = var.external_node_termination.queue.name
  message_retention_seconds = var.external_node_termination.queue.message_retention_seconds
  sqs_managed_sse_enabled   = var.external_node_termination.queue.sqs_managed_sse_enabled
  policy                    = data.aws_iam_policy_document.node_termination_queue_policy.json
  tags                      = var.tags
}

resource "aws_iam_role" "node_termination_role" {
  name               = var.external_node_termination.role_name
  assume_role_policy = data.aws_iam_policy_document.node_termination_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "node_termination_access_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AutoScalingNotificationAccessRole"
  role       = aws_iam_role.node_termination_role.name
}

data "aws_iam_policy_document" "node_termination" {
  statement {
    effect = "Allow"
    actions = [
      "ecr-public:GetAuthorizationToken",
      "sts:GetServiceBearerToken",
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "node_termination_policy" {
  name   = var.external_node_termination.policy_name
  policy = data.aws_iam_policy_document.node_termination.json
}

resource "aws_iam_role_policy_attachment" "node_termination_policy_attachment" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.node_termination_policy.arn
}

resource "aws_autoscaling_lifecycle_hook" "node_termination" {
  name                    = var.external_node_termination.autoscaling_lifecycle_hook.name
  autoscaling_group_name  = module.ec2_worker_instance.auto_scaling_group_name
  default_result          = var.external_node_termination.autoscaling_lifecycle_hook.default_result
  heartbeat_timeout       = var.external_node_termination.autoscaling_lifecycle_hook.heartbeat_timeout
  lifecycle_transition    = var.external_node_termination.autoscaling_lifecycle_hook.lifecycle_transition
  notification_target_arn = aws_sqs_queue.node_termination.arn
  role_arn                = aws_iam_role.node_termination_role.arn
}