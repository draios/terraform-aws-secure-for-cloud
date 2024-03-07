resource "aws_eks_access_entry" "viewer" {
  for_each      = var.clusters
  cluster_name  = each.value
  principal_arn = local.principal_arn // TODO: Use data source
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "viewer" {
  for_each      = var.clusters
  cluster_name  = each.value
  policy_arn    = local.policy_arn
  principal_arn = local.principal_arn // TODO: Use data source
  access_scope {
    type = "cluster"
  }
}
