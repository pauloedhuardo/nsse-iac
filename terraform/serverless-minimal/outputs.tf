output "queue_urls" {
  value = aws_sqs_queue.nsse.*.id
}

output "queuedlq_urls" {
  value = aws_sqs_queue.nsse_deadletter.*.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.order_confirmed_topic.id
}

output "route53_zone_name_servers" {
  value = data.aws_route53_zone.this.name_servers
}
