# =============================================================================
# IAM Roles and Policies for Jenkins Controller and Agent
# =============================================================================

# -----------------------------------------------------------------------------
# Jenkins Controller IAM Role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "jenkins_controller_role" {

  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = var.iam_role_name
    }
  )

}

# SSM Managed Instance Core (for Session Manager)

resource "aws_iam_role_policy_attachment" "controller_ssm_core" {

  role       = aws_iam_role.jenkins_controller_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}

# Custom S3 Policy for Controller (Get and Push only)
resource "aws_iam_role_policy" "controller_s3_policy" {
  name = "${var.iam_role_name}-s3-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3GetAndPushAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = var.s3_bucket_arns
      }
    ]
  })
}

# Custom ECR Policy for Controller (Full Access except Delete)
resource "aws_iam_role_policy" "controller_ecr_policy" {
  name = "${var.iam_role_name}-ecr-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRLogin"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRFullAccessExceptDelete"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages",
          "ecr:ListTagsForResource",
          "ecr:CreateRepository",
          "ecr:TagResource",
          "ecr:UntagResource",
          "ecr:GetLifecyclePolicy",
          "ecr:GetRepositoryPolicy",
          "ecr:SetRepositoryPolicy",
          "ecr:PutLifecyclePolicy",
          "ecr:PutImageScanningConfiguration",
          "ecr:PutImageTagMutability",
          "ecr:StartImageScan",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:StartLifecyclePolicyPreview"
        ]
        Resource = var.ecr_repository_arns
      },
      {
        Sid    = "ECRDenyDelete"
        Effect = "Deny"
        Action = [
          "ecr:BatchDeleteImage",
          "ecr:DeleteRepository",
          "ecr:DeleteRepositoryPolicy",
          "ecr:DeleteLifecyclePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# Custom EC2 Policy for Controller (Full Access)
resource "aws_iam_role_policy" "controller_ec2_policy" {
  name = var.iam_custom_policy_name
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2FullAccess"
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      {
        Sid      = "IAMPassRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = var.iam_passrole_arn
      },
      {
        Sid    = "IAMDescribe"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetPolicy",
          "iam:GetUser",
          "iam:GetGroup",
          "iam:ListRoles",
          "iam:ListPolicies",
          "iam:ListUsers",
          "iam:ListGroups",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:ListInstanceProfiles",
          "iam:GetInstanceProfile",
          "iam:GetRolePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# Custom EKS Policy for Controller (Full Access)
resource "aws_iam_role_policy" "controller_eks_policy" {
  name = "${var.iam_role_name}-eks-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSFullAccess"
        Effect = "Allow"
        Action = [
          "eks:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Custom IAM Read-Only Policy for Controller
resource "aws_iam_role_policy" "controller_iam_readonly_policy" {
  name = "${var.iam_role_name}-iam-readonly-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "IAMReadOnly"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetPolicy",
          "iam:GetUser",
          "iam:GetGroup",
          "iam:ListRoles",
          "iam:ListPolicies",
          "iam:ListUsers",
          "iam:ListGroups",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:ListInstanceProfiles",
          "iam:GetInstanceProfile",
          "iam:GetRolePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "jenkins_controller_profile" {

  name = var.iam_instance_profile_name

  role = aws_iam_role.jenkins_controller_role.name

}

# Jenkins Agent IAM Role

resource "aws_iam_role" "jenkins_agent_role" {

  name = var.jenkins_agent_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = var.jenkins_agent_role_name
    }
  )
}


# SSM Managed Instance Core (for Session Manager)

resource "aws_iam_role_policy_attachment" "agent_ssm_core" {

  role       = aws_iam_role.jenkins_agent_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

}

# Custom S3 Policy for Agent (read/write artifacts)

resource "aws_iam_role_policy" "agent_s3_policy" {

  name = "${var.jenkins_agent_role_name}-s3-policy"

  role = aws_iam_role.jenkins_agent_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "S3ArtifactsAccess"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]

        Resource = var.s3_bucket_arns
      }
    ]
  })

}

# Custom ECR Policy for Agent (pull only)

resource "aws_iam_role_policy" "agent_ecr_policy" {

  name = "${var.jenkins_agent_role_name}-ecr-policy"

  role = aws_iam_role.jenkins_agent_role.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [

      {
        Sid    = "ECRLogin"
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      {
        Sid    = "ECRPull"
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:ListImages"
        ]

        Resource = var.ecr_repository_arns
      }

    ]
  })

}

resource "aws_iam_instance_profile" "jenkins_agent_profile" {

  name = var.jenkins_agent_instance_profile_name

  role = aws_iam_role.jenkins_agent_role.name

}

