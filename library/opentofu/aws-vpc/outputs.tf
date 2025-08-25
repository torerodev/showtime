output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnet_ids" {
  value = { for cidr, subnet in aws_subnet.subnets : subnet.tags.Name => subnet.id }
}