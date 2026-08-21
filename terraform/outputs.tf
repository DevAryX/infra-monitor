output "instance_id" {
  description = "ID of the infra-monitor EC2 instance."
  value       = aws_instance.infra_monitor.id
}

output "public_ip" {
  description = "Current public IP address of the infra-monitor EC2 instance."
  value       = aws_instance.infra_monitor.public_ip
}

output "public_dns" {
  description = "Public DNS name of the infra-monitor EC2 instance."
  value       = aws_instance.infra_monitor.public_dns
}

output "security_group_id" {
  description = "ID of the Terraform-created Security Group."
  value       = aws_security_group.infra_monitor_sg.id
}

output "elastic_ip" {
  description = "Elastic IP address attached to the infra-monitor EC2 instance."
  value       = aws_eip.infra_monitor_eip.public_ip
}

output "deployment_host" {
  description = "Stable public IP used by GitHub Actions and SSH deployment."
  value       = aws_eip.infra_monitor_eip.public_ip
}

output "ssh_command" {
  description = "SSH command used to connect to the infra-monitor EC2 instance using the Elastic IP."
  value       = "ssh -i ssh/infra-monitor-key.pem ec2-user@${aws_eip.infra_monitor_eip.public_ip}"
}

output "ec2_iam_role_name" {
  description = "IAM role used by the infra-monitor EC2 instance."
  value       = aws_iam_role.infra_monitor_ec2.name
}

output "ec2_instance_profile_name" {
  description = "IAM instance profile attached to the infra-monitor EC2 instance."
  value       = aws_iam_instance_profile.infra_monitor.name
}

output "s3_upload_policy_arn" {
  description = "ARN of the least-privilege Infra Monitor S3 upload policy."
  value       = aws_iam_policy.infra_monitor_s3_upload.arn
}
