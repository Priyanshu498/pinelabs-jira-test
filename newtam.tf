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
      },
      {
        Sid    = ""
        Effect = "Allow"

        Principal = {
          AWS = "arn:aws:iam::154495061904:role/r_cplus_maven"
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

# -----------------------------------------------------------------------------
# Managed Policy 1: S3 Full Access to Specific Buckets
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "controller_s3_policy" {
  name = "${var.iam_role_name}-s3-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VisualEditor0"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::cplus-mvn-repo/*",
          "arn:aws:s3:::cplus-helm-chart-repo/*",
          "arn:aws:s3:::endbd-auto-code-deploy/*",
          "arn:aws:s3:::endbd-auto-code-deploy",
          "arn:aws:s3:::enbd-prod-auto-code-deploy",
          "arn:aws:s3:::enbd-prod-auto-code-deploy/*",
          "arn:aws:s3:::cf-templates-b62t017jk0mm-ap-south-2",
          "arn:aws:s3:::cf-templates-b62t017jk0mm-ap-south-2/*",
          "arn:aws:s3:::cf-templates-b62t017jk0mm-me-south-1",
          "arn:aws:s3:::cf-templates-b62t017jk0mm-me-south-1/*"
        ]
      },
      {
        Sid    = "Statement1"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::cplus-mvn-repo",
          "arn:aws:s3:::cplus-helm-chart-repo",
          "arn:aws:s3:::cplus-mvn-repo/*",
          "arn:aws:s3:::cplus-helm-chart-repo/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Managed Policy 2: ECR Full Access + CloudTrail
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "controller_ecr_full_policy" {
  name = "${var.iam_role_name}-ecr-full-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:*",
          "cloudtrail:LookupEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = [
              "replication.ecr.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Managed Policy 3: ECR Push/Pull (Detailed Actions)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "controller_ecr_pushpull_policy" {
  name = "${var.iam_role_name}-ecr-pushpull-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:BatchGetImage",
          "ecr:GetLifecyclePolicy",
          "ecr:GetLifecyclePolicyPreview",
          "ecr:ListTagsForResource",
          "ecr:DescribeImageScanFindings",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Managed Policy 4: SSM + SSM Messages + EC2 Messages
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "controller_ssm_policy" {
  name = "${var.iam_role_name}-ssm-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Inline Policy 1: STS AssumeRole to svc_jenkins
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "controller_sts_policy" {
  name = "${var.iam_role_name}-sts-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "VisualEditor0"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = "arn:aws:iam::154495061904:role/svc_jenkins"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Inline Policy 2: CodeArtifact + STS GetServiceBearerToken
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "controller_codeartifact_policy" {
  name = "${var.iam_role_name}-codeartifact-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codeartifact:GetAuthorizationToken",
          "codeartifact:GetRepositoryEndpoint",
          "codeartifact:ReadFromRepository",
          "codeartifact:PublishPackageVersion",
          "sts:GetServiceBearerToken"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Inline Policy 3: S3 Wide Read + Full Access to woohoo bucket
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "controller_s3_woohoo_policy" {
  name = "${var.iam_role_name}-s3-woohoo-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VisualEditor0"
        Effect = "Allow"
        Action = [
          "s3:GetAccessPoint",
          "s3:PutAccountPublicAccessBlock",
          "s3:GetAccountPublicAccessBlock",
          "s3:ListAllMyBuckets",
          "s3:ListAccessPoints",
          "s3:ListJobs",
          "s3:CreateJob",
          "s3:HeadBucket"
        ]
        Resource = "*"
      },
      {
        Sid    = "VisualEditor1"
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::cplus-woohoo-auto-code-deploy",
          "arn:aws:s3:::cplus-woohoo-auto-code-deploy/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Inline Policy 4: S3 Detailed Read + KMS + Multi-bucket Full Access
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "controller_s3_detailed_policy" {
  name = "${var.iam_role_name}-s3-detailed-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VisualEditor0"
        Effect = "Allow"
        Action = [
          "s3:GetAccessPoint",
          "s3:GetLifecycleConfiguration",
          "s3:GetBucketTagging",
          "s3:GetInventoryConfiguration",
          "s3:GetObjectVersionTagging",
          "s3:ListBucketVersions",
          "s3:GetBucketLogging",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketPolicy",
          "s3:GetObjectVersionTorrent",
          "s3:GetObjectAcl",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketRequestPayment",
          "kms:*",
          "s3:GetAccessPointPolicyStatus",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectTagging",
          "s3:GetMetricsConfiguration",
          "s3:HeadBucket",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketPolicyStatus",
          "s3:ListBucketMultipartUploads",
          "s3:PutAccountPublicAccessBlock",
          "s3:GetObjectRetention",
          "s3:GetBucketWebsite",
          "s3:ListAccessPoints",
          "s3:ListJobs",
          "s3:GetBucketVersioning",
          "s3:GetBucketAcl",
          "s3:GetObjectLegalHold",
          "s3:GetBucketNotification",
          "s3:GetReplicationConfiguration",
          "s3:ListMultipartUploadParts",
          "s3:GetObject",
          "s3:GetObjectTorrent",
          "s3:GetAccountPublicAccessBlock",
          "s3:ListAllMyBuckets",
          "s3:DescribeJob",
          "s3:GetBucketCORS",
          "s3:GetAnalyticsConfiguration",
          "s3:GetObjectVersionForReplication",
          "s3:CreateJob",
          "s3:GetBucketLocation",
          "s3:GetAccessPointPolicy",
          "s3:GetObjectVersion"
        ]
        Resource = "*"
      },
      {
        Sid    = "VisualEditor1"
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::cplus-woohoo-auto-code-deploy/*",
          "arn:aws:s3:::drmea-woohoo-auto-code-deploy/*",
          "arn:aws:s3:::drapac-woohoo-auto-code-deploy/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Inline Policy 5: KMS Decrypt
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "controller_kms_policy" {
  name = "${var.iam_role_name}-kms-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "VisualEditor0"
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Inline Policy 6: CodeBuild + S3 + CloudWatch Logs
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "controller_codebuild_policy" {
  name = "${var.iam_role_name}-codebuild-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Resource = [
          "arn:aws:logs:ap-south-1:154495061904:log-group:/aws/codebuild/*:*"
        ]
        Action = [
          "logs:GetLogEvents"
        ]
      },
      {
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::cplus-woohoo-auto-code-deploy"
        ]
        Action = [
          "s3:GetBucketVersioning"
        ]
      },
      {
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::cplus-woohoo-auto-code-deploy/*"
        ]
        Action = [
          "s3:PutObject"
        ]
      },
      {
        Effect = "Allow"
        Resource = [
          "arn:aws:codebuild:ap-south-1:154495061904:project/*"
        ]
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          "codebuild:BatchGetProjects"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Inline Policy 7: Combined (CodeBuild + S3 + STS + SecretsManager + ECR)
# -----------------------------------------------------------------------------
resource "aws_iam_role_policy" "controller_combined_policy" {
  name = "${var.iam_role_name}-combined-policy"
  role = aws_iam_role.jenkins_controller_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VisualEditor0"
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetProjects",
          "s3:PutObject",
          "s3:GetObject",
          "sts:AssumeRole",
          "secretsmanager:GetSecretValue",
          "logs:GetLogEvents",
          "s3:GetBucketVersioning",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ]
        Resource = [
          "arn:aws:secretsmanager:ap-south-1:154495061904:secret:*",
          "arn:aws:logs:ap-south-1:154495061904:log-group:*",
          "arn:aws:s3:::mvn-repo-rnd/jenkins-poc.zip",
          "arn:aws:s3:::mvn-repo-rnd",
          "arn:aws:iam::154495061904:role/r_cplus_maven",
          "arn:aws:codebuild:*:154495061904:project/*"
        ]
      },
      {
        Sid    = "VisualEditor1"
        Effect = "Allow"
        Action = [
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:GetAuthorizationToken",
          "ecr:UploadLayerPart",
          "ecr:ListImages",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "secretsmanager:ListSecrets",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Jenkins Controller Instance Profile
# -----------------------------------------------------------------------------
resource "aws_iam_instance_profile" "jenkins_controller_profile" {

  name = var.iam_instance_profile_name

  role = aws_iam_role.jenkins_controller_role.name

}

# =============================================================================
# Jenkins Agent IAM Role (unchanged)
# =============================================================================

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
