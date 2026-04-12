variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "iam_role_arn" {
  description = "Terraform이 assume할 IAM Role ARN"
  type        = string
}
