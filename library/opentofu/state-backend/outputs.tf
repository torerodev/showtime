output "s3_bucket_name" {
  description = "Name of the S3 bucket for OpenTofu state"
  value       = aws_s3_bucket.state_bucket.bucket
}

output "s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.state_bucket.region
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.state_lock_table.name
}