terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    region         = "us-east-2"
    bucket         = "torero-showtime-bucket"
    key            = "network/aws/terraform.tfstate"
    dynamodb_table = "torero-showtime-state-lock"
    encrypt        = true
  }

}