resource "random_id" "random" {
  byte_length = 2
}

resource "aws_key_pair" "main_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_instance" "main" {
  count                = var.main_instance_count
  instance_type        = var.main_instance_type
  ami                  = data.aws_ami.server_ami.id # key id or name
  key_name             = aws_key_pair.main_auth.id
  iam_instance_profile = aws_iam_instance_profile.application_profile.id
  vpc_security_group_ids = [
    data.terraform_remote_state.networking.outputs.public_sg_id,
    aws_security_group.application_sg.id
  ]
  subnet_id = data.terraform_remote_state.networking.outputs.main_public_subnet_ids[count.index]

  root_block_device {
    volume_size = var.main_vol_size
  }

  tags = {
    Name = "application_main_${random_id.random.dec}"
  }

  # provisioner's are generally discouraged because they aren't part of terraform state
  provisioner "local-exec" {
    command = "printf '\n${self.public_ip}' >> aws_hosts && aws ec2 wait instance-status-ok --instance-ids ${self.id} --region us-west-2"
  }

  # taint won't work on destroy provisioner
  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/^[0-9]/d' aws_hosts"
  }
}

# Repository for application application images
resource "aws_ecr_repository" "application_image_repo" {
  name         = "application_image"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
