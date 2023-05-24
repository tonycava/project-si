terraform {
  backend "s3" {
    bucket = "tonycava-backend-bucket"
    key    = "terraform.tfstate"
    region = "eu-west-3"
  }
}