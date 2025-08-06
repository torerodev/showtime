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

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "torero-showtime-backend"
}

variable "bucket_name" {
  description = "Unique name for the S3 bucket"
  type        = string
  default     = "torero-showtime-backend"
}

variable "dynamodb_table_name" {
  description = "Name for the DynamoDB lock table"
  type        = string
  default     = "torero-showtime-state-lock"
}