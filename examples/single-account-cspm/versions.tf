terraform {
  required_version = ">= 1.3.0"
  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    aws = {
      version = ">= 4.0.0"
    }
  }
}
