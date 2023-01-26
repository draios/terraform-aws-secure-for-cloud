terraform {
  required_providers {
    sysdig = {
      source = "sysdiglabs/sysdig"
    }
  }
}

provider "sysdig" {
  sysdig_secure_api_token = var.sysdig_secure_api_token
  sysdig_secure_url       = var.sysdig_secure_url
}

provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "cloudvision_aws_single_account_k8s" {
  source           = "../../../examples/single-account-k8s"
  name             = "${var.name}-singlek8s"
  trusted_identity = "arn:aws:iam::064689838359:role/us-east-1-integration01-secure-assume-role"
  external_id      = "b26e5d571ba8f8646e06ff8a8963a84b"
}
