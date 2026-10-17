variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "ssh_ingress_cidr" {
  description = "CIDR allowed to SSH into the dev machine (operator IP, e.g. 203.0.113.4/32)"
  type        = string

  validation {
    condition     = var.ssh_ingress_cidr != "0.0.0.0/0"
    error_message = "ssh_ingress_cidr must not be 0.0.0.0/0. Use your own IP with /32 instead, for example 203.0.113.4/32."
  }
}

variable "ssh_public_key" {
  description = "SSH public key for the dev machine key pair (passed as TF_VAR_ssh_public_key at apply time, never committed)"
  type        = string
}
