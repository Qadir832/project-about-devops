
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.calculator_server.id
}

output "public_ip" {
  description = "EC2 public IP address"
  value       = aws_instance.calculator_server.public_ip
}

output "website_url" {
  description = "Calculator website URL"
  value       = "http://${aws_instance.calculator_server.public_ip}"
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.calculator_sg.id
}
