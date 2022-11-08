module "cspm" {
  source = "../../modules/services/trust-relationship"
  count  = var.deploy_cspm ? 1 : 0

  name              = "${var.name}-cspm"
  tags = var.tags
}
