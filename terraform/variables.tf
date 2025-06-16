variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "webserver"
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "admin_username" {
  description = "Administrator username for the instance"
  type        = string
  default     = "ubuntu"
}

variable "public_key_path" {
  description = "Path to the public SSH key"
  type        = string
  default     = "../jenkins_ssh_key.pub"
}
