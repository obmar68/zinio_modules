variable "additional_user_data_script" {
  description = "Additional user data script (default=\"\")"
  default     = ""
}

variable "environment" {
  description = "Environment"
  default     = ""
}

variable "asg_max_size" {
  description = "Maximum number EC2 instances"
  default     = 1
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group that should be associated with the ECS service"
  default     = ""
}

variable "asg_min_size" {
  description = "Minimum number of instances"
  default     = 1
}

# to be removed
variable "asg_desired_size" {
  description = "Desired number of instances"
  default     = 1
}

variable "image_id" {
  description = "AMI image_id for ECS instance"
  default     = ""
}

variable "instance_keypair" {
  description = "Instance keypair name"
  default     = ""
}

variable "instance_log_group" {
  description = "Instance log group in CloudWatch Logs"
  default     = ""
}

variable "instance_root_volume_size" {
  description = "Root volume size (default=50)"
  default     = 50
}

variable "instance_type" {
  description = "EC2 instance type (default=t2.micro)"
  default     = "t3a.micro"
}

variable "name" {
  description = "Base name to use for resources in the module"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

# to be removed
variable "vpc_id" {
  description = "VPC ID to create cluster in"
}

variable "vpc_subnets" {
  description = "List of VPC subnets to put instances in"
  default     = []
}

variable "security_groups" {
  description = "List of Security Groups to put instances in"
  default     = []
}

// variable "capacity_providers" {
//   description = "List of short names of one or more capacity providers to associate with the cluster. Valid values also include FARGATE and FARGATE_SPOT."
//   type        = list(string)
//   default     = []
// }

// variable "default_capacity_provider_strategy" {
//   description = "The capacity provider strategy to use by default for the cluster. Can be one or more."
//   type        = list(map(any))
//   default     = []
// }