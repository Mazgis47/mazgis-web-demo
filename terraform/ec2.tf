# resource "aws_subnet" "subnet-drone" {
#     vpc_id     = module.vpc.vpc_id
#     cidr_block = "10.0.7.0/24"
#     availability_zone = data.aws_availability_zones.available.names[0]

#     tags = {
#         Name = "Drone EC2 subnet"
#     }
# }

# module "ec2_instance" {
#     source  = "terraform-aws-modules/ec2-instance/aws"
#     version = "~> 3.0"

#     name = "single-instance"

#     #   ami                    = "ami-ebd02392"
#     ami                    = "ami-06d38f60e724550c9"
#     instance_type          = "t2.micro"
#     key_name               = "user1"
#     monitoring             = true
#     vpc_security_group_ids = [ aws_security_group.all_worker_mgmt.id, aws_security_group.all_https.id ]
#     subnet_id              = aws_subnet.subnet-drone.id

#     tags = {
#         Terraform   = "true"
#         Environment = "dev"
#     }
#     user_data = <<EOF
#     #!/bin/bash
#     echo "Preparing Drone"
#     sudo yum install docker
#     EOF
# }