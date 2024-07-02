variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
}

variable "public_subnets" {
  description = "A list of public subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "A list of private subnets"
  type        = list(string)
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "account_number" {
  description = "The AWS account number"
  type        = string
}

variable "env" {
  description = "The environment (e.g., dev, prd)"
  type        = string
}
