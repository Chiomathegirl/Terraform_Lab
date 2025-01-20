terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
    region = "us-east-1"
    access_key = "$ACCESS_KEY"
    secret_key = "$SECRET_KEY"

}

resource "aws_s3_bucket" "my-thegirly-bucket" {
  bucket = "my-thegirly-bucket"

  tags = {
    Name        = "my first bucket"
  }
}
resource "aws_s3_bucket_object" "train" {
  bucket = "my-thegirly-bucket"
  key    = "train_image"
  source = "C:\\Users\\CHIOMA\\Downloads\\train.jpg"
  }
