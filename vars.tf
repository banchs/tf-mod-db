# VARIABLES
variable "env" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "name" {
  description = "rds-demo-devops"
  default     = "rds-demo-devops"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Resource Tags"
  type        = map(string)
}

variable "private_subnets_cidr" {
  default = []
}

variable "private_subnets" {
  default = []
}

variable "public_subnets" {
  default = []
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "kms_key_id" {
  type        = string
  sensitive   = true
  description = "KMS key for Encrypt & Decrypt"
}

variable "security_groups_id" {
  type        = string
  description = "Nodes Access to RDS"
}
