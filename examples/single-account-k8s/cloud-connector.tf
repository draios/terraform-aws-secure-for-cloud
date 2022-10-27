#-------------------------------------
# requirements
#-------------------------------------
module "cloud_connector_sqs" {
  source = "../../modules/infrastructure/sqs-sns-subscription"

  name               = var.name
  cloudtrail_sns_arn = local.cloudtrail_sns_arn
  tags               = var.tags
}

#-------------------------------------
# cloud_connector
#-------------------------------------
resource "helm_release" "cloud_connector" {
  name       = "cloud-connector"
  repository = "https://charts.sysdig.com"
  chart      = "cloud-connector"

  create_namespace = true
  namespace        = var.name

  set {
    name  = "sysdig.url"
    value = data.sysdig_secure_connection.current.secure_url
  }

  set_sensitive {
    name  = "sysdig.secureAPIToken"
    value = data.sysdig_secure_connection.current.secure_api_token
  }

  dynamic "set_sensitive" {
    for_each = var.deploy_aws_iam_user ? [true] : []
    content {
      name  = "aws.accessKeyId"
      value = module.iam_user[0].sfc_user_access_key_id
    }
  }

  dynamic "set_sensitive" {
    for_each = var.deploy_aws_iam_user ? [true] : []
    content {
      name  = "aws.secretAccessKey"
      value = module.iam_user[0].sfc_user_secret_access_key
    }
  }

  set {
    name  = "aws.region"
    value = data.aws_region.current.name
  }

  set {
    name  = "telemetryDeploymentMethod"
    value = "terraform_aws_k8s_single"
  }

  values = [
    yamlencode({
      ingestors = [
        {
          cloudtrail-sns-sqs = {
            queueURL = module.cloud_connector_sqs.cloudtrail_sns_subscribed_sqs_url
          }
        }
      ]
    })
  ]
  depends_on = [module.iam_user[0]]
}
