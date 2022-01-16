# resource "aws_iam_role" "eks_worknode" {
#   name = "${local.cluster_name}-worknode"

#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_role_policy_attachment" "worknode-AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.eks_worknode.name
# }

# resource "aws_iam_role_policy_attachment" "worknode-AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.eks_worknode.name
# }

# resource "aws_iam_role_policy_attachment" "worknode-AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.eks_worknode.name
# }


# resource "aws_iam_policy" "eks_worknode_ebs_policy" {
#   name = "Amazon_EBS_CSI_Driver"

#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "ec2:AttachVolume",
#         "ec2:CreateSnapshot",
#         "ec2:CreateTags",
#         "ec2:CreateVolume",
#         "ec2:DeleteSnapshot",
#         "ec2:DeleteTags",
#         "ec2:DeleteVolume",
#         "ec2:DescribeInstances",
#         "ec2:DescribeSnapshots",
#         "ec2:DescribeTags",
#         "ec2:DescribeVolumes",
#         "ec2:DetachVolume"
#       ],
#       "Resource": "*"
#     }
#   ]
# }
# POLICY
# }

# # And attach the new policy
# # resource "aws_iam_role_policy_attachment" "worknode-AmazonEBSCSIDriver" {
# #   policy_arn = aws_iam_policy.eks_worknode_ebs_policy.arn
# #   role       = aws_iam_role.eks_worknode.name
# # }

# resource "aws_iam_policy" "ext_dns_policy" {
#   name = "ext_dns_policy"

#   policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "route53:ChangeResourceRecordSets"
#       ],
#       "Resource": [
#         "arn:aws:route53:::hostedzone/*"
#       ]
#     },
#     {
#       "Effect": "Allow",
#       "Action": [
#         "route53:ListHostedZones",
#         "route53:ListResourceRecordSets"
#       ],
#       "Resource": [
#         "*"
#       ]
#     }
#   ]
# }
# POLICY
# }

# resource "aws_iam_role_policy_attachment" "worknode-AmazonEBSCSIDriver" {
#   policy_arn = aws_iam_policy.ext_dns_policy.arn
#   role       = aws_iam_role.ext_dns_policy.name
# }

# Step 1
resource "aws_iam_policy" "route53-external-policy" {
  name = "route53-external-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

# Create IAM role for the EKS worker nodes
resource "aws_iam_role" "eks_node_group_iam_role" {
  name = "eks-node-group-iam-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity"
    }
  ]
}
POLICY
}

# Step 2
data "aws_iam_policy_document" "assume-role-document" {
    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
        type = "Service"
        identifiers = ["ec2.amazonaws.com"]
        }
    }

    statement {
        effect = "Allow"
        actions = ["sts:AssumeRole"]
        principals {
            type = "AWS"
            #Set identifiers as arn for the EKS worker nodes
            identifiers = ["${aws_iam_role.eks_node_group_iam_role.arn}"]
        }
    }
}

# Step 3
resource "aws_iam_role" "route53-externaldns-controller" {
  name = "route53-externaldns-controller"
  assume_role_policy = data.aws_iam_policy_document.assume-role-document.json
}


# Step 3
resource "aws_iam_role_policy_attachment" "route53-externaldns-attachment"{
  role = aws_iam_role.route53-externaldns-controller.name
  policy_arn = aws_iam_policy.route53-external-policy.arn
}

############## Secrets mgmt ###########

locals {
  k8s_service_account_name      = "deployment-account"
  k8s_service_account_namespace = "default"
# ​  Get the EKS OIDC Issuer without https:// prefix
  eks_oidc_issuer = trimprefix(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://")
}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "eks" {
  name = "demo-eks-1"
  depends_on = [
    module.eks
  ]
}

# resource "aws_iam_role" "drone-secrets-role" {
#   name = "drone-secrets-role"
#   assume_role_policy = data.aws_iam_policy_document.account-assume-role-document.json
# }

# data "aws_iam_policy_document" "account-assume-role-document" {
#     statement {
#         effect = "Allow"
#         actions = ["sts:AssumeRoleWithWebIdentity"]
#         principals {
#             type = "Federated"
#             identifiers = [
#                 "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer}"
#             ]
#         }
#         # Limit the scope so that only our desired service account can assume this role
#         condition {
#             test     = "StringEquals"
#             variable = "${local.eks_oidc_issuer}:sub"
#             values = [
#                 "system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"
#             ]
#         }
#     }
#     statement {
#         effect = "Allow"
#         actions = ["sts:AssumeRole"]
#         principals {
#             type = "Service"
#             identifiers = ["ec2.amazonaws.com"]
#         }
#     }
#     statement {
#         effect = "Allow"
#         actions = ["sts:AssumeRole"]
#         principals {
#             type = "AWS"
#             #Set identifiers as arn for the EKS worker nodes
#             identifiers = ["${aws_iam_role.eks_node_group_iam_role.arn}"]
#         }
#     }
#     statement    {
#         effect = "Allow"
#         actions = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
#         # resource = ["arn:aws:secretsmanager:us-east-2:173609628671:secret:GITHUB_CLIENT_SECRET-rLyEDD"]
#     }
#     statement {
#         effect = "Allow"
#         actions = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
#         # resource = ["arn:aws:secretsmanager:us-east-2:173609628671:secret:RPC_SECRET-zMZXUW"]
#     }
# }

# resource "aws_iam_role" "account_role" {
#   name = "account-role"

#   assume_role_policy = jsonencode({
#     "Version": "2012-10-17",
#     "Statement": [
#       {
#         "Effect": "Allow",
#         "Principal": {
#           "Federated": format(
#             "arn:aws:iam::${data.aws_caller_identity.current.account_id}:%s",
#             replace(
#               "${data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer}",
#               "https://",
#               "oidc-provider/"
#             )
#           )
#         },
#         "Action": "sts:AssumeRoleWithWebIdentity",
#         "Condition": {
#           "StringEquals": {
#             format(
#               "%s:sub", 
#               trimprefix(
#                 "${data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer}",
#                 "https://"
#               )
#             ) : "system:serviceaccount:default:${local.k8s_service_account_name}"
#           }
#         }
#       }
#     ]
#   })
# }

resource "aws_iam_role" "account_role" {
  name = "account-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                "${local.eks_oidc_issuer}:sub": "system:serviceaccount:default:${local.k8s_service_account_name}"
                }
            }
        }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "drone-deployment-secrets-policy-attachment" {
  role = aws_iam_role.account_role.name
  policy_arn = aws_iam_policy.drone-deployment-secrets-policy.arn
}

resource "aws_iam_policy" "drone-deployment-secrets-policy" {
  name = "drone-deployment-secrets-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource": ["arn:aws:secretsmanager:us-east-2:173609628671:secret:GITHUB_CLIENT_SECRET-rLyEDD"]
    },
    {
        "Effect": "Allow",
        "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
        "Resource": ["arn:aws:secretsmanager:us-east-2:173609628671:secret:RPC_SECRET-zMZXUW"]
    },
    {
        "Effect": "Allow",
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Resource": ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer}"]
    }
  ]
}
EOF
}

resource "kubernetes_service_account" "deployment-service-account" {
  metadata {
    name      = local.k8s_service_account_name
    namespace = local.k8s_service_account_namespace
    annotations = {
      # This annotation is needed to tell the service account which IAM role it
      # should assume
      "eks.amazonaws.com/role-arn" = aws_iam_role.account_role.arn
    }
  }
}