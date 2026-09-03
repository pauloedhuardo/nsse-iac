resource "aws_lb_target_group" "nlb_tcp" {
  name               = var.network_load_balancer.target_group.name
  target_type        = var.network_load_balancer.target_group.target_type
  port               = var.network_load_balancer.target_group.port
  protocol           = var.network_load_balancer.target_group.protocol
  preserve_client_ip = var.network_load_balancer.target_group.preserve_client_ip
  vpc_id             = data.aws_vpc.this.id
}