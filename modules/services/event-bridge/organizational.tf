#-----------------------------------------------------------------------------------------------------------------------
# These resources set up an EventBridge Rule and Target to forward all CloudTrail events from the source account to
# Sysdig in all accounts in an AWS Organization via a CloudFormation StackSet. For a single account installation, see
# main.tf.
#-----------------------------------------------------------------------------------------------------------------------

data "aws_organizations_organization" "org" {
  count = var.is_organizational ? 1 : 0
}

locals {
  organizational_unit_ids = var.is_organizational && length(var.org_units) == 0 ? [for root in data.aws_organizations_organization.org[0].roots : root.id] : toset(var.org_units)
  region_set              = toset(var.regions)
}

# stackset to deploy eventbridge rule in organization unit
resource "aws_cloudformation_stack_set" "eb-rule-stackset" {
  count = var.is_organizational ? 1 : 0

  name             = join("-", [var.name, "EBRuleOrg"])
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  managed_execution {
    active = true
  }

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  lifecycle {
    ignore_changes = [administration_role_arn]
  }

  template_body = templatefile("${path.module}/stackset_template_body.tpl", {
    name                 = var.name
    event_pattern        = var.event_pattern
    rule_state           = var.rule_state
    target_event_bus_arn = var.target_event_bus_arn
  })
}

# stackset to deploy eventbridge rule in management account
resource "aws_cloudformation_stack_set" "mgmt-stackset" {
  count = var.is_organizational && var.mgt_stackset ? 1 : 0

  name                    = join("-", [var.name, "EBRuleMgmtAcc"])
  tags                    = var.tags
  permission_model        = "SELF_MANAGED"
  capabilities            = ["CAPABILITY_NAMED_IAM"]
  administration_role_arn = var.stackset_admin_role_arn

  managed_execution {
    active = true
  }

  template_body = templatefile("${path.module}/stackset_template_body.tpl", {
    name                 = var.name
    event_pattern        = var.event_pattern
    rule_state           = var.rule_state
    target_event_bus_arn = var.target_event_bus_arn
  })
}

# stackset to deploy eventbridge role in organization unit
resource "aws_cloudformation_stack_set" "eb-role-stackset" {
  count = var.is_organizational ? 1 : 0

  name             = join("-", [var.name, "EBRoleOrg"])
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  managed_execution {
    active = true
  }

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  lifecycle {
    ignore_changes = [administration_role_arn]
  }

  template_body = <<TEMPLATE
Resources:
  EventBridgeRole:
      Type: AWS::IAM::Role
      Properties:
        RoleName: ${var.name}
        AssumeRolePolicyDocument:
          Version: "2012-10-17"
          Statement:
            - Effect: Allow
              Principal:
                Service: events.amazonaws.com
              Action: 'sts:AssumeRole'
            - Effect: "Allow"
              Principal:
                AWS: "${var.trusted_identity}"
              Action: "sts:AssumeRole"
              Condition:
                StringEquals:
                  sts:ExternalId: "${var.external_id}"
        Policies:
          - PolicyName: ${var.name}
            PolicyDocument:
              Version: "2012-10-17"
              Statement:
                - Effect: Allow
                  Action: 'events:PutEvents'
                  Resource: ${var.target_event_bus_arn}
                - Effect: Allow
                  Action:
                    - "events:DescribeRule"
                    - "events:ListTargetsByRule"
                  Resource: "arn:aws:events:*:*:rule/${var.name}"
TEMPLATE
}

// stackset instance to deploy rule in all organization units
resource "aws_cloudformation_stack_set_instance" "stackset_instance" {
  for_each = local.region_set
  region   = each.key

  stack_set_name = aws_cloudformation_stack_set.eb-rule-stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    #    max_concurrent_count    = 10
    max_concurrent_percentage    = 100
    failure_tolerance_percentage = 100
    region_concurrency_type      = "PARALLEL"
  }

  timeouts {
    create = var.timeout
    update = var.timeout
    delete = var.timeout
  }
}

// stackset instance to deploy rule in all regions of management account
resource "aws_cloudformation_stack_set_instance" "mgmt_acc_stackset_instance" {
  for_each       = var.mgt_stackset ? local.region_set : toset([])
  region         = each.key
  stack_set_name = aws_cloudformation_stack_set.mgmt-stackset[0].name

  operation_preferences {
    #    max_concurrent_count    = 10
    max_concurrent_percentage    = 100
    failure_tolerance_percentage = 100
    region_concurrency_type      = "PARALLEL"
  }

  timeouts {
    create = var.timeout
    update = var.timeout
    delete = var.timeout
  }
}

// stackset instance to deploy role in all organization units
resource "aws_cloudformation_stack_set_instance" "eb_role_stackset_instance" {
  count = var.is_organizational ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.eb-role-stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    #    max_concurrent_count    = 10
    max_concurrent_percentage    = 100
    failure_tolerance_percentage = 100
    // Roles are not regional and hence do not need regional parallelism
  }

  timeouts {
    create = var.timeout
    update = var.timeout
    delete = var.timeout
  }
}
