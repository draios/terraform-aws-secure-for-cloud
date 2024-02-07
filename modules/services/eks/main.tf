# import {
#   for_each = local.filtered_clusters
#   to       = aws_eks_cluster.this[each.key]
#   id       = each.value.id
# }

// TODO: Open public access manually
# resource "aws_eks_cluster" "this" {
#   for_each = local.filtered_clusters // TODO: Is the import order preserved? 
#   name     = each.value.name
#   role_arn = each.value.role_arn
# 
#   vpc_config {
#     endpoint_private_access = false
#     endpoint_public_access  = true
#     public_access_cidrs     = concat(local.sysdig_cidrs, [for cidr in each.value.vpc_config.0.public_access_cidrs : cidr if cidr != "0.0.0.0/0"])
#     security_group_ids      = each.value.vpc_config.0.security_group_ids
#     subnet_ids              = each.value.vpc_config.0.subnet_ids
#   }
# 
#   tags       = each.value.tags
# }

// TODO: Check if it already exists (in case if the customer runs this script twice)
resource "awscc_eks_access_entry" "viewer" {
  for_each        = local.clusters
  cluster_name    = each.value.name
  principal_arn   = var.principal_arn // TODO: Use data source
  access_policies = [local.cluster_access_policy]
}

