output "eip" {
  value = aws_eip.public_ip.public_ip
}

output "security_group_arn" {
  value = aws_security_group.nat.arn
}

output "security_group_id" {
  value = aws_security_group.nat.id
}

output "eni_id" {
  value = aws_network_interface.nat.id
}
