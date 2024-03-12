locals {
  account_id    = data.aws_caller_identity.current.account_id
  principal_arn = "arn:aws:iam::${local.account_id}:role/${var.eks_role_name}"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  n = var.deploy_global_resources ? 1 : 0
}
