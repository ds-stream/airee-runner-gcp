# RUNNER-CONTAINER for GCP

## Overview

The github-action runner container designed for the airee project. The first container launches a github action runner and the second container runs a daemon docker. They cooperate with each other and therefore the runner is able to run docker containers while executing CI/CD pipelines.

The runner-container app for gcp contain bash script which:
- Enable all services and APIs for runner and Airee
- create GKE cluster for runner
- build and publish runner-app and airee-base images on GCR
- set up runner app on cluster 

Script can be run localy. Requirements:
- gcloud cli  - loggeed as a project owner to set up infrastructure
- kubectl - for set up app on cluster
- docker - to build and publish images for runner-app and Airee base image

## How to use

Script is placed in root foder here ./setup.sh

Params:
- -p {project_id} - gcp project-id - owner role needed - <b>Required</b>
- -r {runner_cluster_name} - name of cluster - default "runner-cluster"
- -o {gh_org} - name of GitHub Organization where GH Self-Hosted runner will be created - <b>Required</b>
- -t {gh_token} - Personal Access Token to GitHub. Token with at least two permissions: "admin:enterprise" and "admin:org" - <b>Required</b>
- -g {gke_region} - GKE region, default us-central1-c
- -l {gke_node_location} - GKE node location, default us-central1-c
- -n {gke_node_num} - GKE node number, default 1
- -m {gke_machine_type} - GKE node machine type, default e2-standard-2
- -s {sa_name} - GCP Service Acount name, default "runner-sa"
- -a {ghr_labels} - GitHub runner labels. Provide labes separated by comma without spaces, e.g: "gcp,test,runner,airee". Default value: "gcp,airflow"
- -i {replica_num} - number of runners, default 1

Examples of usage:

Base usage with default values
```bash
bash setup.sh -p infra-sandbox-352609 -o DsAirKube -t PERSONALTOKEN
```

Set up two runners
```bash
bash setup.sh -p infra-sandbox-352609 -o DsAirKube -t PERSONALTOKEN -i 2
```

Custom labels
```bash
bash setup.sh -p infra-sandbox-352609 -o DsAirKube -t PERSONALTOKEN -a gcp,airee,prod
```

## Script steps

- set variables base on params
- check if gcloud, kubectl and docker apps are on env
- set default project
- enable all services/apis
- create cluster or update if exists
- create service account with role grant or update if exists
- create workload identity for k8s sa
- create key for sa and push it to Secret Menager or update if exists
- push github PAT to Secret Menager or update if exists
- auth docker to GCR
- build runner-app and airee-base images and push it to GCR
- set up runner-app on cluster
