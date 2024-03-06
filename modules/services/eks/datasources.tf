data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "clusters" {
  for_each = toset(var.clusters)
  name     = each.value
}
