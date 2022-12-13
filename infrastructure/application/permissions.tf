# Generate a policy document that will allow
# the ec2 instance to assume the role 
data "aws_iam_policy_document" "application_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "application_role_policy" {
  statement {
    actions   = ["ecr:*"]
    resources = [aws_ecr_repository.application_image_repo.arn]
  }

  statement {
    actions = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

# Instance profile to attach to application instance
resource "aws_iam_instance_profile" "application_profile" {
  name = "application_ec2_profile_${random_id.random.dec}"
  role = aws_iam_role.application_role.name
}

resource "aws_iam_role" "application_role" {
  name               = "application_role_${random_id.random.dec}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.application_assume_role_policy.json

  inline_policy {
    name = "application_role_policy_${random_id.random.dec}"
    policy = data.aws_iam_policy_document.application_role_policy.json
  }
}
