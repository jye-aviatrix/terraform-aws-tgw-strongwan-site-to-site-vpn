terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    http = {
      source  = "registry.terraform.io/hashicorp/http"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region1
}

provider "aws" {
  alias  = "secondary"
  region = var.region2
}
