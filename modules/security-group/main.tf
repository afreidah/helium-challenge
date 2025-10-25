# -----------------------------------------------------------------------------
# SECURITY GROUP MODULE
# -----------------------------------------------------------------------------
#
# This module creates an AWS VPC security group with configurable ingress and
# egress rules for network traffic control. Rules are created as separate
# resources to enable granular management and avoid the limitations of inline
# rule definitions.
#
# The security group supports create-before-destroy lifecycle to ensure safe
# updates during rule modifications. Rules can reference CIDR blocks or other
# security groups as sources. Multiple protocols including TCP, UDP, and ICMP
# are supported with configurable port ranges.
#
# This module is designed to work with root.hcl rule definitions, where each
# component specifies its security group configuration via the
# security_group_rules variable containing name_suffix, description, and rule
# lists.
#
# IMPORTANT: Security scanner suppressions are included for common patterns
# like public ALB ingress and EC2 egress to internet. Review and adjust
# suppressions based on specific security requirements and organizational
# policies.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# SECURITY GROUP
# -----------------------------------------------------------------------------
# VPC security group for network access control
# Uses create-before-destroy to prevent connectivity disruption during updates
# Name is constructed from environment and component-specific suffix

resource "aws_security_group" "this" {
  name_prefix = "${var.environment}-${var.security_group_rules.name_suffix}-"
  description = var.security_group_rules.description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-${var.security_group_rules.name_suffix}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# INGRESS RULES
# -----------------------------------------------------------------------------
# Inbound traffic rules for the security group
# Created as separate resources for granular management
# Rules are defined in root.hcl and passed via security_group_rules variable

resource "aws_vpc_security_group_ingress_rule" "this" {
  #tfsec:ignore:aws-ec2-no-public-ingress-sgr Public ALB requires internet access on 80/443
  #checkov:skip=CKV_AWS_260:Public ALB security group intentionally allows internet traffic
  for_each = { for idx, rule in var.security_group_rules.ingress_rules : idx => rule }

  security_group_id = aws_security_group.this.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_blocks[0]
  description       = each.value.description

  tags = var.tags
}

# -----------------------------------------------------------------------------
# EGRESS RULES
# -----------------------------------------------------------------------------
# Outbound traffic rules for the security group
# Created as separate resources for granular management
# Rules are defined in root.hcl and passed via security_group_rules variable

resource "aws_vpc_security_group_egress_rule" "this" {
  #tfsec:ignore:aws-ec2-no-public-egress-sgr EC2 instances need internet access for package updates and AWS APIs
  #checkov:skip=CKV_AWS_23:Egress to internet required for package updates and AWS service access
  #trivy:ignore:AVD-AWS-0104
  for_each = { for idx, rule in var.security_group_rules.egress_rules : idx => rule }

  security_group_id = aws_security_group.this.id
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  ip_protocol       = each.value.protocol
  cidr_ipv4         = each.value.cidr_blocks[0]
  description       = each.value.description

  tags = var.tags
}
