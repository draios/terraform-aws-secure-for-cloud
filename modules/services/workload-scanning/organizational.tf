#-----------------------------------------------------------------------------------------------------------------------
# Determine if this is an Organizational install, or a single account install. For Organizational installs, resources
# are created using CloudFormation StackSet. For Single Account installs see main.tf.
#-----------------------------------------------------------------------------------------------------------------------

data "aws_organizations_organization" "org" {
  count = var.is_organizational ? 1 : 0
}

locals {
  organizational_unit_ids = var.is_organizational && length(var.org_units) == 0 ? [for root in data.aws_organizations_organization.org[0].roots : root.id] : toset(var.org_units)
}

#-----------------------------------------------------------------------------------------------------------------------
# The resources in this file set up an Agentless Workload Scanning IAM Role and Policies in all accounts
# in an AWS Organization via a CloudFormation StackSet.
# Global resources: IAM Role and Policy
#-----------------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------------------
# stackset and stackset instance deployed in organization units for Agentless Scanning IAM Role, Policies
#-----------------------------------------------------------------------------------------------------------------------

# stackset to deploy agentless workload scanning role in organization unit
resource "aws_cloudformation_stack_set" "scanning_role_stackset" {
  count = var.is_organizational ? 1 : 0

  name             = join("-", [var.ecr_role_name, "ScanningRoleOrg"])
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  lifecycle {
    ignore_changes = [administration_role_arn]
  }

  template_body = <<TEMPLATE
Resources:
  SysdigAgentlessWorkloadRole:
      Type: AWS::IAM::Role
      Properties:
        RoleName: ${var.ecr_role_name}
        AssumeRolePolicyDocument:
          Version: "2012-10-17"
          Statement:
            - Sid: "SysdigSecureScanning"
              Effect: "Allow"
              Action: "sts:AssumeRole"
              Principal:
                AWS: "${var.trusted_identity}"
              Condition:
                StringEquals:
                  sts:ExternalId: "${var.external_id}"
        Policies:
          - PolicyName: ${var.ecr_role_name}
            PolicyDocument:
              Version: "2012-10-17"
              Statement:
                - Sid: "EcrReadPermissions"
                  Effect: "Allow"
                  Action:
                    - "ecr:GetDownloadUrlForLayer"
                    - "ecr:BatchGetImage"
                    - "ecr:BatchCheckLayerAvailability"
                    - "ecr:ListImages"
                    - "ecr:GetAuthorizationToken"
                  Resource: "*"

TEMPLATE
}

# stackset instance to deploy agentless scanning role, in all organization units
resource "aws_cloudformation_stack_set_instance" "scanning_role_stackset_instance" {
  count = var.is_organizational ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.scanning_role_stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    max_concurrent_count = 10
  }

  timeouts {
    create = var.timeouts["create"]
    update = var.timeouts["update"]
    delete = var.timeouts["delete"]
  }
}
