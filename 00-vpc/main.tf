module "vpc" {
    source = "git::https://github.com/prasanth-devsecops-labs/terraform-aws-vpc.git?ref=main"
    project = var.project
    environment = var.environment
    is_peering_required = true
}