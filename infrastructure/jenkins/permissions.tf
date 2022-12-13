# Generate a policy document for 'terraform_role' that will allow
# the ec2 instance to assume the role 
data "aws_iam_policy_document" "terraform_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Instance profile to attach to jenkins instance
# This will allow terraform to be run within jenkins
resource "aws_iam_instance_profile" "terraform_profile" {
  name = "terraform_ec2_profile_${random_id.random.dec}"
  role = aws_iam_role.terraform_role.name
}

resource "aws_iam_role_policy" "terraform_policy" {
  name = "terraform_policy_${random_id.random.dec}"
  role = aws_iam_role.terraform_role.id

  /*
    This is the minimum policy terraform needs to run 'terraform init'.
    Note this is not needed because we are giving the instance admin access,
    but it is good to know.
  */
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "s3:ListBucket"
        Effect   = "Allow"
        Resource = "arn:aws:s3:::terraform-state-ljustint-tutorial" # TODO: Replace "terraform-state-ljustint" with the name of your backend bucket
      },
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Effect = "Allow",
        Resource = "arn:aws:s3:::terraform-state-ljustint-tutorial/*" # TODO: Replace "terraform-state-ljustint" with the name of your backend bucket
      }
    ]
  })
}

resource "aws_iam_role" "terraform_role" {
  name = "terraform_role_${random_id.random.dec}"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.terraform_assume_role_policy.json

  /*
    NOTE: For the sake of the tutorial we want our instance to have adminstrator access.
    Make sure only YOU can ssh into your instance. Anyone who can ssh into the instance 
    will have adminstrator access to your aws account.

    In a real project, it would be best to create a role with fine-grained policies.
    For example, if all you are doing is creating EC2 servers, then Jenkins
    should only have access to do what it needs to accomplish that task.
  */
  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}
