# NOTE: Bucket is passed in at runtime to support multiple environments
# This is done by using the terraform -backend-config flag
# Ex: terraform init -backend-config="bucket=myproject-terraform-state"
terraform {
  backend "gcs" {
    # bucket = "<NAME_OF_BUCKET>" # See note above
    prefix = "infra"
  }
}
