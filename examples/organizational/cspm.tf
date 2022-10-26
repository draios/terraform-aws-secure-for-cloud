# note; had to split cspm module due to not being able to use dynamics on provider
# https://github.com/hashicorp/terraform/issues/25244

module "cspm_org" {
  count = var.deploy_benchmark && var.deploy_benchmark_organizational ? 1 : 0

  source = "../../modules/services/cspm"

  name              = "${var.name}-cspm"
  is_organizational = true
  region            = data.aws_region.current.name
  benchmark_regions = var.benchmark_regions

  tags = var.tags
}

module "cspm_single" {
  count1 = var.deploy_benchmark && !var.deploy_benchmark_organizational ? 1 : 0
  providers = {
    aws = aws.member
  }

  source = "../../modules/services/cspm"

  name              = "${var.name}-cspm"
  is_organizational = false
  region            = data.aws_region.current.name
  benchmark_regions = var.benchmark_regions

  tags = var.tags
}
