# locals {
#     ebs_block_device = {
#         block_device_name = "/dev/sdc",
#         volume_type = "gp2"
#         volume_size = "1"
#     }
# }

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.24.0"
  cluster_name    = local.cluster_name
  cluster_version = "1.20"
  subnets         = module.vpc.private_subnets

  vpc_id = module.vpc.vpc_id

  workers_group_defaults = {
    root_volume_type = "gp2"
    iam_role_arn = aws_iam_role.eks_node_group_iam_role.arn
  }

  worker_groups = [
    {
      name                          = "worker-group-1"
      instance_type                 = "t2.medium"
      additional_userdata           = "echo foo bar"
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
      asg_desired_capacity          = 1
      # additional_ebs_volumes        = [local.ebs_block_device]
    },
    # {
    #   name                          = "worker-group-2"
    #   instance_type                 = "t2.medium"
    #   additional_userdata           = "echo foo bar"
    #   additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
    #   asg_desired_capacity          = 1
    # },
  ]
  depends_on = [
    aws_iam_role_policy_attachment.route53-externaldns-attachment,
    # aws_iam_role_policy_attachment.worknode-AmazonEKSWorkerNodePolicy,
    # aws_iam_role_policy_attachment.worknode-AmazonEKS_CNI_Policy,
    # aws_iam_role_policy_attachment.worknode-AmazonEC2ContainerRegistryReadOnly,
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# resource "aws_efs_file_system" "db" {
#   creation_token = "drone-db"

#   tags = {
#     Name = "DroneDB"
#   }
# }