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
