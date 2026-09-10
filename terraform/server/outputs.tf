output "key_pair_private_key" {
  sensitive = true
  value     = tls_private_key.this.private_key_pem
}
output "nlb_dns_name" {
  value = aws_lb.nlb_control_plane.dns_name
}

output "worker_launch_template_id" {
  value = module.ec2_worker_instance.launch_template_id
}

output "node_termination_queue_url" {
  value = aws_sqs_queue.node_termination.id
}
# ARN para preencher a variable AWS_BACKEND_ROLE_TO_ASSUME no environment
# production do repositorio not-so-simple-ecommerce.
output "github_backend_role_arn" {
  value = aws_iam_role.github_backend.arn
}
