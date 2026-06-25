# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform
resource "neon_project" "pileup_db" {
  allowed_ips_protected_branches_only = null
  block_public_connections            = null
  block_vpc_connections               = null
  compute_provisioner                 = "k8s-neonvm"
  enable_logical_replication          = null
  history_retention_seconds           = 86400
  name                                = "pileupDatabase"
  org_id                              = "org-noisy-bird-87662227"
  pg_version                          = 17
  region_id                           = "aws-eu-west-2"
  store_password                      = "yes"
  branch {
    database_name = "neondb"
    name          = "production"
    role_name     = "neondb_owner"
  }
  default_endpoint_settings {
    autoscaling_limit_max_cu = 2
    autoscaling_limit_min_cu = 0.25
    suspend_timeout_seconds  = 0
  }
  maintenance_window {
    end_time   = "04:00"
    start_time = "03:00"
    weekdays   = [3]
  }
}
