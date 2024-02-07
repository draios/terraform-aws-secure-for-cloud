output "eks_clusers" {
  value = local.clusters
}

// DEBUG ONLY
output "eks_clusers_api_enabled" {
  value = [for cluster in local.api_enabled_clusters : cluster.name]
}
