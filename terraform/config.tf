terraform {
  required_version = ">= 1.0"

  # You can override the backend configuration; this is  given as an example.
  backend "s3" {
    encrypt = true
    bucket = "kaveri-lab"
    key    = "os-eks-terraform/terraform.tfstate"
    region = "ap-southeast-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.69"
    }
  }
}

provider "aws" {}