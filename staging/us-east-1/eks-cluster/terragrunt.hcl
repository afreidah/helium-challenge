# -----------------------------------------------------------------------------
# EKS CLUSTER
# -----------------------------------------------------------------------------
# Creates a production-ready Amazon Elastic Kubernetes Service (EKS) cluster
# with security hardening, encryption, logging, and IRSA support.
#
# Configuration:
#   - Kubernetes version and settings defined in root.hcl
#   - Secrets encrypted at rest using KMS
#   - Control plane logging to CloudWatch
#   - Private and/or public API endpoint access
#   - Automated EKS add-on management (VPC CNI, CoreDNS, kube-proxy)
#
# Dependencies:
#   - general-networking (VPC, private subnets for control plane)
#   - kms (encryption key for secrets and CloudWatch logs)
#
# Outputs:
#   - cluster_id: EKS cluster identifier
#   - cluster_endpoint: Kubernetes API server endpoint
#   - cluster_oidc_issuer_url: OIDC provider URL for IRSA
#   - cluster_certificate_authority_data: CA cert for kubectl config
#
# Next Steps After Deployment:
#   1. Deploy eks-node-group component
#   2. Update manage_aws_auth_configmap to true (after nodes exist)
#   3. Configure kubectl: aws eks update-kubeconfig --name <cluster_name>
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "eks_cluster" {
  path = "${get_repo_root()}/_env_helpers/eks-cluster.hcl"
}
