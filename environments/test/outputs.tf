output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.oidc_provider.oidc_provider_arn
}

output "role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = module.oidc_provider.role_arn
}

output "role_name" {
  description = "Name of the GitHub Actions IAM role"
  value       = module.oidc_provider.role_name
}
