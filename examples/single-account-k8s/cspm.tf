module "cspm" {
  source = "../../modules/services/cspm"
  count  = var.deploy_cspm ? 1 : 0

  name              = "${var.name}-cspm"
  tags = var.tags
}
