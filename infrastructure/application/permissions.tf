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

# resource "aws_iam_role_policy" "application_policy" {
#   name = "application_policy_${random_id.random.dec}"
#   role = aws_iam_role.application_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "s3:ListBucket"
#         Effect   = "Allow"
#         Resource = "arn:aws:s3:::terraform-state-ljustint-tutorial" # TODO: Replace "terraform-state-ljustint" with the name of your backend bucket
#       },
#       {
#         Action = [
#           "s3:GetObject",
#           "s3:PutObject",
#           "s3:DeleteObject"
#         ],
#         Effect = "Allow",
#         Resource = "arn:aws:s3:::terraform-state-ljustint-tutorial/*" # TODO: Replace "terraform-state-ljustint" with the name of your backend bucket
#       }
#     ]
#   })
# }

resource "aws_iam_role" "application_role" {
  name               = "application_role_${random_id.random.dec}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.application_assume_role_policy.json

  inline_policy {
    name = "application_role_policy_${random_id.random.dec}"
    policy = data.aws_iam_policy_document.application_role_policy.json
  }
}
