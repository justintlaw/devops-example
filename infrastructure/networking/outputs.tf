# Outputs allow us to reference values in other terraform states
# You can also get these values by typing 'terraform output'
output "vpc_id" {
  value = aws_vpc.main.id
}

output "main_public_subnet_ids" {
  value = "${aws_subnet.main_public_subnet.*.id}"
}

output "public_sg_id" {
  value = aws_security_group.public_sg.id
}
