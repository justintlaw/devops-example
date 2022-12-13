resource "random_id" "random" {
  byte_length = 2
}

resource "aws_key_pair" "main_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# Using an elastic IP is helpful for jenkins because you don't have to
# Worry about updating the ip for webhooks etc.
resource "aws_eip" "jenkins_eip" {
  depends_on = [
    aws_instance.main
  ]

  instance = aws_instance.main.id
  vpc = true
  network_border_group = "us-west-2"

  tags = {
    Name = "Jenkins Public IP"
  }

  /*
    Local exec allows you to run arbitrary scripts within a resource block.
    They are generally discouraged because they are not a part of Terraform state,
    but they can be useful for some things.

    "local-exec" for example, allows us to run a script on our local machine that
    is associated with the resource block. In the code below, we output the elastic ip
    of our Jenkins instance to a file called "aws_hosts", which will be useful once
    we start using ansible.
  */
  provisioner "local-exec" {
    command = "printf '\n${self.public_ip}' >> aws_hosts"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/^[0-9]/d' aws_hosts"
  }
}

resource "aws_instance" "main" {
  instance_type          = var.main_instance_type
  ami                    = data.aws_ami.server_ami.id # key id or name
  key_name               = aws_key_pair.main_auth.id
  iam_instance_profile   = aws_iam_instance_profile.terraform_profile.id
  vpc_security_group_ids = [
    aws_security_group.jenkins_sg.id,
    local.networking.public_sg_id
  ]
  subnet_id              = local.networking.main_public_subnet_ids[0]

  root_block_device {
    volume_size = var.main_vol_size
  }

  tags = {
    Name = "jenkins_main_${random_id.random.dec}"
  }

  # provisioner's are generally discouraged because they aren't part of terraform state
  provisioner "local-exec" {
    command = "aws ec2 wait instance-status-ok --instance-ids ${self.id} --region us-west-2"
  }

  # Uncomment the below code if you don't want the server to redeploy when the ubuntu ami is updated
  lifecycle {
    ignore_changes = [ami]
  }
}

/*
  You can combine "null_resource" with the "local-exec" command to execute 
  Arbitrary scripts on creation of a resource. This local-exec installs jenkins
  using ansible, for example.
*/
# resource "null_resource" "jenkins_install" {
#   depends_on = [aws_instance.main]

#   provisioner "local-exec" {
#     command = "ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i aws_hosts --key-file ~/.ssh/devops_key ../../playbooks/jenkins.yml"
#   }
# }
