locals {
  api_enabled_clusters = [
    for cluster in data.aws_eks_cluster.clusters :
    cluster if contains(["API", "API_AND_CONFIG_MAP"], cluster.access_config[0].authentication_mode)
  ]

  tag_key = "sysdig:secure:scan"
  tag_opt_in_values = ["true", "all"]
  opted_in_clusters = [
    for cluster in local.api_enabled_clusters :
    cluster if var.onboard_all_clusters || contains(var.clusters, cluster.name) || contains(local.tag_opt_in_values, lookup(cluster.tags, local.tag_key, "false"))
  ]

  clusters = {
    for cluster in local.opted_in_clusters : cluster.name => cluster
    // Only onboard public clusters or clusters that Sysdig has access to
    if cluster.vpc_config[0].endpoint_public_access
  }

  eks_view_policy = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  cluster_access_policy = {
    access_scope = {
      type = "cluster"
    }
    policy_arn = local.eks_view_policy
  }
}
