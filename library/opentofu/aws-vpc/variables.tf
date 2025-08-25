variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region to create resources in"
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.250.0.0/24"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "vpc-torero-showtime"
}

variable "subnet_cidrs" {
  description = "Subnet CIDR blocks"
  type        = list(string)
  default     = ["10.250.1.0/24", "10.250.2.0/24", "10.250.3.0/24"]
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}