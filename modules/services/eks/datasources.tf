data "aws_eks_clusters" "clusters" {}

data "aws_eks_cluster" "clusters" {
  for_each = toset(data.aws_eks_clusters.clusters.names)
  name     = each.value
}
