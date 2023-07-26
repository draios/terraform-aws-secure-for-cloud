provider "aws" {
  region     = "us-east-1"
  access_key = "test"
  secret_key = "test"

  endpoints {
    iam    = "http://127.0.0.1:5000/"
    sts    = "http://127.0.0.1:5000/"
    events = "http://127.0.0.1:5000/"
  }
}

module "single-account-threat-detection" {
  source                  = "../../../..//modules/services/event-bridge"
  target_event_bus_arn    = "arn:aws:events:us-east-1:123456789012:event-bus/falco"
  trusted_identity        = "arn:aws:iam::123456789012:role/secure-assume-role"
  external_id             = "external_id"
  name                    = "secure-threat-detection-single"
  deploy_global_resources = true
}
