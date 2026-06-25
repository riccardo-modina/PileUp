data "google_project" "pileup_backend" {
  project_id = "financeappbackend"
}

resource "google_cloud_run_v2_service" "pileup_backend" {
  annotations      = {}
  client           = "gcloud"
  client_version   = "538.0.0"
  custom_audiences = []
  description      = null
  ingress          = "INGRESS_TRAFFIC_ALL"
  labels           = {}
  launch_stage     = "GA"
  location         = "europe-west1"
  name             = "pileup-backend"
  project          = "financeappbackend"
  template {
    annotations                      = {}
    encryption_key                   = null
    execution_environment            = null
    labels                           = {}
    max_instance_request_concurrency = 80
    revision                         = null
    service_account                  = "552035049143-compute@developer.gserviceaccount.com"
    session_affinity                 = false
    timeout                          = "300s"
    containers {
      args        = []
      command     = []
      depends_on  = []
      image       = "europe-west1-docker.pkg.dev/financeappbackend/financeappbackend/financeapp-backend:latest"
      name        = "financeapp-backend-1"
      working_dir = null
      env {
        name  = "DJANGO_SECRET_KEY"
        value = var.django_secret_key
      }
      env {
        name  = "DATABASE_URL"
        value = var.database_url
      }
      env {
        name  = "APP_MODE"
        value = "cloud"
      }
      env {
        name  = "RUN_MIGRATIONS"
        value = "false"
      }
      env {
        name  = "DJANGO_DEBUG"
        value = "false"
      }
      ports {
        container_port = 8080
        name           = "http1"
      }
      resources {
        cpu_idle = true
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
        startup_cpu_boost = true
      }
      startup_probe {
        failure_threshold     = 1
        initial_delay_seconds = 0
        period_seconds        = 240
        timeout_seconds       = 240
        tcp_socket {
          port = 8080
        }
      }
    }
    scaling {
      max_instance_count = 20
      min_instance_count = 0
    }
  }
  traffic {
    percent  = 100
    revision = null
    tag      = null
    type     = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = google_cloud_run_v2_service.pileup_backend.project
  location = google_cloud_run_v2_service.pileup_backend.location
  name     = google_cloud_run_v2_service.pileup_backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
