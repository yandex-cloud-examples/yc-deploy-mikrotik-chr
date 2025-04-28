# =================
# Global parameters
# =================

variable "cloud_id" {
  description = "YC cloud-id. Taken from environment variable."
}

variable "folder_id" {
  description = "YC folder-id. Taken from environment variable."
}

variable "seed_ip" {
  description = "Public IP address of system where Terraform is running. Taken from environment variable."
}

variable "allowed_ip_list" {
  description = "List of legitimate IP prefixes sources for connect to CHR."
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "Compute Zone Id."
  default     = null
}

variable "vpc_subnet_id" {
  description = "VPC Subnet Id."
  default     = null
}

variable "chr_image_folder_id" {
  description = "folder-id where CHR Image is located."
  default     = null
}

variable "chr_image_id" {
  description = "CHR Image ID"
  default     = null
}

variable "chr_name" {
  description = "CHR Name"
  default     = null
}

variable "chr_ip" {
  description = "CHR IP address"
  default     = null
}

variable "admin_name" {
  description = "CHR Admin name"
  default     = null
}

variable "admin_key_file" {
  description = "User's admin SSH key file for the CHR."
  default     = null
}
