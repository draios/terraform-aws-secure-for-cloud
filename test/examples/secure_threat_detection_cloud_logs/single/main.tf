provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  endpoints {
    iam = "http://127.0.0.1:5000/"
    sts = "http://127.0.0.1:5000/"
  }
}

module "single-account-threat-detection" {
  source           = "../../../..//modules/services/cloud-logs"
  trusted_identity = "arn:aws:iam::123456789012:role/secure-assume-role"
  external_id      = "external_id"
  role_name        = "sysdig-secure-single"
  bucket_name      = "sample-bucket-name"
}
