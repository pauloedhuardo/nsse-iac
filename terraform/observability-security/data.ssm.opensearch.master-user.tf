data "aws_ssm_parameter" "master_user_name" {
  name = var.opensearch_master_user.ssm_parameter_name
}

data "aws_ssm_parameter" "master_user_password" {
  name = var.opensearch_master_user.ssm_parameter_password
}
