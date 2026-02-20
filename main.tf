# -------------------------
# Network Module
# -------------------------

module "network" {

  source = "./module-network"
  env     = var.env
  program = var.program
  owner   = var.owner

  # Existing VPC Resources
  existing_vpc_id           = var.existing_vpc_id
  existing_public_subnet_ids  = var.existing_public_subnet_ids
  existing_private_subnet_ids = var.existing_private_subnet_ids
  create_nacl        = false
  create_route53     = false
  # enable_s3_endpoint = var.enable_s3_endpoint
  # enable_ec2_endpoint = false
  # enable_nlb_endpoint = false
  create_nlb        = false
  create_key_pair   = true
  create_private_key = true
  # Flow Logs (optional)
  # flow_logs_enabled      = true
  # flow_logs_traffic_type = "ALL"
  # flow_logs_file_format  = "plain-text"
  # ALB Configuration
  create_alb = true
  internal   = var.alb_internal
  alb_sg_id  = module.alb_sg.id[0]
  # Listener Configuration
  alb_listeners = var.alb_listeners

}



# -------------------------
# ALB Security Group
# -------------------------

module "alb_sg" {
  source = "./module-sg"
  name   = "${local.base_name}-alb-sg"
  vpc_id = module.network.vpc_id
  tags = merge(
    local.common_tags,
    {
      Name = lower(
        join(
          "-",
          [
            var.env,
            var.program,
            "alb",
            "sg"
          ]
        )
      )
    }
  )

  aws_security_group_variables = [
    {
      description = "ALB Security Group"
      aws_security_group_ingress = var.alb_ingress_rules
      aws_security_group_egress  = var.alb_egress_rules
    }
  ]

}


# -------------------------
# Jenkins Controller Security Group
# -------------------------

module "jenkins_sg" {
  source = "./module-sg"
  name   = "${local.base_name}-sg"
  vpc_id = module.network.vpc_id
  tags = merge(
    local.common_tags,
    {
      Name = lower(
        join(
          "-",
          [
            var.env,
            var.program,
            "ec2-sg"
          ]
        )
      )
    }
  )

  aws_security_group_variables = [
    {
      description = "Jenkins Security Group"
      aws_security_group_ingress = [

        {
          description     = "Jenkins console access from ALB"
          from_port       = 8080
          to_port         = 8080
          protocol        = "tcp"
          security_groups = module.alb_sg.id
        },

        {
          description     = "Jenkins agent communication"
          from_port       = var.jenkins_agent_port
          to_port         = var.jenkins_agent_port
          protocol        = "tcp"
          security_groups = module.jenkins_agent_sg.id
        }
      ]
      aws_security_group_egress = var.jenkins_egress_rules

    }
  ]

  depends_on = [
    module.jenkins_agent_sg
  ]
}


# -------------------------
# Jenkins Agent Security Group
# -------------------------
module "jenkins_agent_sg" {
  source = "./module-sg"
  name   = var.jenkins_agent_sg_name
  vpc_id = module.network.vpc_id
  tags = merge(
    local.common_tags,
    {
      Name = var.jenkins_agent_sg_name
    }
  )
  aws_security_group_variables = [
    {
      description = "Jenkins Agent Security Group"
      aws_security_group_ingress = var.jenkins_agent_ingress_rules
      aws_security_group_egress  = var.jenkins_agent_egress_rules
    }
  ]
}

# -------------------------
# Jenkins Controller EC2 Instance
# -------------------------

module "jenkins_master_ec2" {
  source = "./module-ec2"

  create_ec2_instance = true
  count_ec2_instance  = 1

  ami_id        = var.jenkins_ami_id
  instance_type = var.jenkins_instance_type

  subnet    = module.network.private_subnet_ids
  public_ip = false

  instance_sg_id       = module.jenkins_sg.id[0]
  iam_instance_profile = aws_iam_instance_profile.jenkins_controller_profile.name
  key_name        = var.key_name
  create_key_pair = false

  volume_size = var.jenkins_volume_size
  volume_type = var.jenkins_volume_type
  user_data = var.jenkins_user_data

  env         = var.env
  program     = var.program
  owner       = var.owner
  Description = var.Description

}

# -------------------------
# Jenkins Agent EC2 Instance
# -------------------------

module "jenkins_agent_ec2" {
  source = "./module-ec2"

  create_ec2_instance = true
  count_ec2_instance  = 2

  ami_id        = var.jenkins_ami_id
  instance_type = var.jenkins_instance_type

  subnet    = module.network.private_subnet_ids
  public_ip = false

  instance_sg_id       = module.jenkins_sg.id[0]
  iam_instance_profile = aws_iam_instance_profile.jenkins_controller_profile.name
  key_name        = var.key_name
  create_key_pair = false

  volume_size = var.jenkins_volume_size
  volume_type = var.jenkins_volume_type
  user_data = var.jenkins_user_data

  env         = var.env
  program     = var.program
  owner       = var.owner
  Description = var.Description

}

# -------------------------
# Jenkins Target Group and ALB Attachment
# -------------------------

module "jenkins_target_group" {
  source = "./module-tg"

  application_name                = var.jenkins_tg_name
  application_port                = var.jenkins_tg_port
  application_health_check_target = var.jenkins_health_check_path

  tg_protocol = var.jenkins_tg_protocol
  vpc_id = module.network.vpc_id

  attach_instances = true
  instance_ids     = module.jenkins_master_ec2.ec2_instance_ids

  add_listener_rule      = true
  listener_arn           = module.network.alb_http_listener_arn
  listener_rule_priority = var.listener_rule_priority
  listener_path_patterns = var.jenkins_listener_path_patterns

  depends_on = [
    module.jenkins_master_ec2
  ]

}
