# File: terraform/variables.tf

# Variable for environment
variable "environment" {
  description = "The deployment environment (e.g., dev, staging, prod)"
  type        = string
  default     = "dev" # Optional default value
}