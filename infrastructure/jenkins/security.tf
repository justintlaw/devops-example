resource "aws_security_group" "jenkins_sg" {
  name = "jenkins_sg_${random_id.random.dec}"
  description = "Security group for jenkins"
  vpc_id = local.networking.vpc_id

  lifecycle {
    create_before_destroy = true
  }
}

# Allow access to jenkins port
# It must be open to all to allow github to connect
resource "aws_security_group_rule" "ingress_jenkins" {
  type = "ingress"
  from_port = 8080
  to_port = 8080
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins_sg.id
}
