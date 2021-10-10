variable "vpc_dns_support" {
  description = "Toggle VPC DNS support"
  type = bool
  default = true
}

variable "availability_zone" {
  description = "A list of allowed availability zones."
  type = list(any)
  default = [
    "eu-west-2a",
    "eu-west-2c"]
}

variable "ecs_image_url" {
  description = "URI of image ECR tasks should pull"
  type = string
  default = "586276181644.dkr.ecr.eu-west-2.amazonaws.com/cake-app:latest"
}


