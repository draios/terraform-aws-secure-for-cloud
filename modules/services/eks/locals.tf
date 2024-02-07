locals {
  api_enabled_clusters = [
    for cluster in data.aws_eks_cluster.clusters :
    cluster if contains(["API", "API_AND_CONFIG_MAP"], cluster.access_config.0.authentication_mode) && (var.onboard_all_clusters || contains(var.clusters, cluster.name))
  ]

  sysdig_cidrs = ["54.218.164.215/32", "54.244.190.180/32", "44.232.85.27/32"]
  clusters = {
    for cluster in local.api_enabled_clusters : cluster.name => cluster
    // Only onboard public clusters or clusters that Sysdig has access to
    if cluster.vpc_config.0.endpoint_public_access && (contains(cluster.vpc_config.0.public_access_cidrs, "0.0.0.0/0") || contains(cluster.vpc_config.0.public_access_cidrs, local.sysdig_cidrs[0]))
  }

  eks_view_policy = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  cluster_access_policy = {
    access_scope = {
      type = "cluster"
    }
    policy_arn = local.eks_view_policy
  }
}
