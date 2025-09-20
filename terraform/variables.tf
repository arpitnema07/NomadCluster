variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "instance_type" {
  description = "EC2 instance type for Nomad servers and clients"
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 20.04 LTS"
  type        = string
  default     = "ami-001ff1531cad381bf" # Ubuntu Server 20.04 LTS (HVM), SSD Volume Type (us-east-1)
}

variable "key_name" {
  description = "SSH Key Pair name for EC2 instances"
  type        = string
}

variable "nomad_server_count" {
  description = "Number of Nomad server instances"
  type        = number
  default     = 1
}

variable "nomad_client_count" {
  description = "Number of Nomad client instances"
  type        = number
  default     = 1
}
