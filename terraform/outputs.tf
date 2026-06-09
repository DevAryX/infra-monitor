output "instance_id" {
  description = "ID of the infra-monitor EC2 instance."
  value       = aws_instance.infra_monitor.id
}

output "public_ip" {
  description = "Public IP address of the infra-monitor EC2 instance."
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

output "ssh_command" {
  description = "SSH command used to connect to the infra-monitor EC2 instance."
  value       = "ssh -i ssh/infra-monitor-key.pem ec2-user@${aws_instance.infra_monitor.public_ip}"
}
