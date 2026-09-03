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
    name                     = string
    cidr_block               = string
    internet_gateway_name    = string
    nat_gateway_name         = string
    eip_name                 = string
    public_route_table_name  = string
    private_route_table_name = string
    public_subnets = list(object({
      name                    = string
      cidr_block              = string
      availability_zone       = string
      map_public_ip_on_launch = bool
    }))
    private_subnets = list(object({
      name                    = string
      cidr_block              = string
      availability_zone       = string
      map_public_ip_on_launch = bool
    }))
  })

  default = {
    name                     = "nsse-production-vpc-p"
    cidr_block               = "10.0.0.0/24"
    internet_gateway_name    = "internet_gateway"
    nat_gateway_name         = "nat-gateway"
    eip_name                 = "nat-gateway"
    public_route_table_name  = "public-route-table"
    private_route_table_name = "pprivate-route-table"
    public_subnets = [
      {
        name                    = "public-subnet-us-east-1a"
        cidr_block              = "10.0.0.0/27"
        availability_zone       = "us-east-1a"
        map_public_ip_on_launch = true
      },
      {
        name                    = "public-subnet-us-east-1b"
        cidr_block              = "10.0.0.64/27"
        availability_zone       = "us-east-1b"
        map_public_ip_on_launch = true
      }
    ]
    private_subnets = [
      {
        name                    = "private-subnet-us-east-1a"
        cidr_block              = "10.0.0.32/27"
        availability_zone       = "us-east-1a"
        map_public_ip_on_launch = false
      },
      {
        name                    = "private-subnet-us-east-1b"
        cidr_block              = "10.0.0.96/27"
        availability_zone       = "us-east-1b"
        map_public_ip_on_launch = false
      }
    ]
  }
}

variable "domain" {
  type = string

  default = "s2sinovatec.com"
}