locals {
  account_id    = data.aws_caller_identity.current.account_id
  principal_arn = "arn:aws:iam::${local.account_id}:role/${var.eks_role_name}"

  api_enabled_clusters = [
    for cluster in data.aws_eks_cluster.clusters :
    cluster if contains(["API", "API_AND_CONFIG_MAP"], cluster.access_config[0].authentication_mode)
  ]

  clusters = {
    for cluster in local.api_enabled_clusters : cluster.name => cluster
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

  // ECR role to pull images
  n = var.deploy_global_resources ? 1 : 0
}

output "validate_cluster_authentication_mode" {
  value = null
  precondition {
    condition     = length(var.clusters) > 0 && length(var.clusters) == length(local.clusters)
    error_message = "Some clusters are not API-enabled. Sysdig Agentless only supports API-enabled clusters."
  }
}
