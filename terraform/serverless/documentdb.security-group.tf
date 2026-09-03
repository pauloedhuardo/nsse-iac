resource "aws_security_group" "documentdb" {
  name        = var.security_groups.documentdb
  description = "Managing ports for DocumentDB"
  vpc_id      = data.aws_vpc.this.id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(var.tags, {
    Name = var.security_groups.documentdb
  })
}

resource "aws_security_group_rule" "documentdb_worker" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.worker.id
  security_group_id        = aws_security_group.documentdb.id
}

resource "aws_security_group_rule" "documentdb_control_plane" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.control_plane.id
  security_group_id        = aws_security_group.documentdb.id
}

resource "aws_security_group_rule" "documentdb_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.documentdb.id
}