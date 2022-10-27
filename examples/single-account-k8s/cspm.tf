module "cspm" {
  source = "../../modules/services/cspm"
  count  = var.deploy_benchmark ? 1 : 0

  name              = "${var.name}-cspm"
  benchmark_regions = var.benchmark_regions

  tags = var.tags
}
