variable "aws_region" {
  description = "AWS region used for the infra-monitor Terraform resources."
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name used for AWS resource naming and tags."
  type        = string
  default     = "infra-monitor"
}

variable "environment" {
  description = "Environment name for tagging resources."
  type        = string
  default     = "learning"
}

variable "instance_type" {
  description = "EC2 instance type used for the infra-monitor server."
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidr" {
  description = "Public IP address allowed to SSH into the EC2 instance, written as a CIDR block."
  type        = string
}

variable "key_name" {
  description = "Name of the existing AWS EC2 key pair used for SSH access."
  type        = string
}

variable "s3_bucket_name" {
  description = "Existing S3 bucket that receives the Infra Monitor system report."
  type        = string
}

variable "s3_object_key" {
  description = "Exact S3 object key that the EC2 workload is allowed to upload."
  type        = string
  default     = "system_report.log"
}
