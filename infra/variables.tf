variable "aws_region" {
  description = "AWS region for all resources."

  type    = string
  default = "eu-west-3"
}

variable "subnet_id_1" {
  type = string
  default = "subnet-018ee195861959eab"
}

variable "subnet_id_2" {
  type = string
  default = "subnet-050012a56d207c06c"
}

variable "webhook_discord_url" {
  type = string
  default = ""
}

variable "account_id" {
  type = string
  default = ""
}