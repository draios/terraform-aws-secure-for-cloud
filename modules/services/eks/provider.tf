# Cluster region
provider "aws" {
  region = var.region
}

provider "awscc" {
  region = var.region
}
