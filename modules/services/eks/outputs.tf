output "onboarded_clusters" {
  value = [for cluster in local.clusters : cluster.name]
}
