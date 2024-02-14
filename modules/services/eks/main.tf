resource "awscc_eks_access_entry" "viewer" {
  for_each        = local.clusters
  cluster_name    = each.value.name
  principal_arn   = local.principal_arn // TODO: Use data source
  access_policies = [local.cluster_access_policy]
}
