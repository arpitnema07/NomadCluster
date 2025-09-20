output "nomad_server_public_ips" {
  description = "Public IPs of Nomad server instances"
  value       = aws_instance.nomad_server[*].public_ip
}

output "nomad_client_public_ips" {
  description = "Public IPs of Nomad client instances"
  value       = aws_instance.nomad_client[*].public_ip
}

output "nomad_ui_url" {
  description = "URL for Nomad UI (accessible via SSH tunnel to server 0 on port 4646)"
  value       = "http://${aws_instance.nomad_server[0].public_ip}:4646"
}
