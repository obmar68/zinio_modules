terraform {
  required_version = ">= 0.12.19"

  required_providers {
    aws = ">= 3.0"
  }
}

provider "aws" {
  region = var.region
}