terraform {
  backend "gcs" {
    bucket = "platform-starter-kit-tf-state"
    prefix = "envs/stg"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "vpc" {
  source     = "../../modules/vpc"
  project_id = var.project_id
  region     = var.region
}

module "gke" {
  source       = "../../modules/gke"
  project_id   = var.project_id
  region       = var.region
  cluster_name = var.cluster_name
  network      = module.vpc.network
  subnet       = module.vpc.subnet
}