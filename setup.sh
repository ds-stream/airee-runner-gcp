#!/bin/bash
# params

while getopts p:r:t:g:l:n:m:s:a:o:i:b: flag
do
    case "${flag}" in
        p) tmp_project_id=${OPTARG};;
        r) tmp_runner_cluster_name=${OPTARG};;
        o) tmp_gh_org=${OPTARG};;
        t) tmp_gh_token=${OPTARG};;
        g) tmp_gke_region=${OPTARG};;
        l) tmp_gke_node_location=${OPTARG};;
        n) tmp_gke_node_num=${OPTARG};;
        m) tmp_gke_machine_type=${OPTARG};;
        s) tmp_sa_name=${OPTARG};;
        a) tmp_ghr_labels=${OPTARG};;
        i) tmp_replica_num=${OPTARG};;
        b) tmp_bucket_name=${OPTARG};;
    esac
done

# target vars with default values:
# dsstream-airflowk8s
project_id="${tmp_project_id}"
runner_cluster_name="${tmp_runner_cluster_name:-runner-cluster}"
gh_org="${tmp_gh_org}"
gh_token="${tmp_gh_token}"
gke_region="${tmp_gke_region:-us-central1-c}"
gke_node_location="${tmp_gke_node_location:-us-central1-c}"
gke_node_num="${tmp_gke_node_num:-1}"
gke_machine_type="${tmp_gke_machine_type:-e2-standard-2}"
sa_name="${tmp_sa_name:-runner-sa}"
ghr_labels="${tmp_ghr_labels:-gcp,airflow}"
replica_num="${tmp_replica_num:-1}"
bucket_name="${tmp_bucket_name}"

# echo "project_id: $project_id"
# echo "runner_cluster_name : $runner_cluster_name"
# echo "gh_org: $gh_org"
# echo "gh_token : $gh_token"
# echo "gke_region: $gke_region"
# echo "gke_node_location: $gke_node_location"
# echo "gke_node_num: $gke_node_num"
# echo "gke_machine_type: $gke_machine_type"
# echo "sa_name: $sa_name"
# echo "ghr_labels: $ghr_labels"
# echo "replica_num: ${replica_num}"

# Check applications that we will need
# check if user have a gcloud
echo "Checking gcloud"
if ! command -v gcloud version 2> /dev/null
then
    echo "gcloud could not be found"
    exit 1
else
    echo "gcloud OK"
fi
# check if user have a docker
echo "Checking docker"
if ! command -v docker -v 2> /dev/null
then
    echo "docker could not be found"
    exit 1
else
    echo "docker OK"
fi
# check if user have a kubectl
echo "Checking kubectl"
if ! command -v kubectl version --client=true 2> /dev/null
then
    echo "kubectl could not be found"
    exit 1
else
    echo "kubectl OK"
fi

# Check if user is connected to gcp and project exists
if [[ $(gcloud projects list --filter="project_id:${project_id}") != "" ]]
then
    echo "Project ${project_id} exists, set project as default"
    gcloud config set project ${project_id}
else
    echo "Project ${project_id} not exists or user not logged"
    exit 1
fi

# Enable services for Ariee
echo "Enable required services for Airee"
# Secrets
gcloud services enable secretmanager.googleapis.com
# Sql admin 
gcloud services enable sqladmin.googleapis.com
# servicenetworking
gcloud services enable servicenetworking.googleapis.com
# IAM
gcloud services enable iamcredentials.googleapis.com
gcloud services enable iam.googleapis.com
# domain
gcloud services enable domains.googleapis.com
gcloud services enable dns.googleapis.com 
# deploymentmanager
gcloud services enable deploymentmanager.googleapis.com
# gcr
gcloud services enable artifactregistry.googleapis.com
gcloud services enable containersecurity.googleapis.com
gcloud services enable containerregistry.googleapis.com
# k8s
gcloud services enable containerfilesystem.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable autoscaling.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
# cloud
gcloud services enable cloudasset.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Check if cluster exists if not create one
if [[ $(gcloud container clusters list --filter="name:${runner_cluster_name}") != "" ]]
then
    echo "Cluster ${runner_cluster_name} exists, update to provided conf"
    gcloud container clusters update ${runner_cluster_name} \
        --region="${gke_region}" \
        --node-locations="${gke_node_location}"
    gcloud container clusters update ${runner_cluster_name} \
        --region="${gke_region}" \
        --workload-pool="${project_id}.svc.id.goog"
    gcloud container clusters resize -q ${runner_cluster_name} \
        --region ${gke_region} \
        --node-pool "default-pool" \
        --num-nodes ${gke_node_num}
    # Machine type cant be change in place, new pool needs to be created
else
    echo "Cluster ${runner_cluster_name} not exists, creating cluster"
    gcloud container clusters create ${runner_cluster_name} \
        --region ${gke_region} \
        --node-locations ${gke_node_location} \
        --num-nodes ${gke_node_num} \
        --machine-type "${gke_machine_type}" \
        --workload-pool="${project_id}.svc.id.goog"
fi

# Check if SA exists if not create one
if [[ $(gcloud iam service-accounts list --filter="email:${sa_name}@${project_id}.iam.gserviceaccount.com") != "" ]]
then
    echo "Service account ${sa_name} exist, update permissions"
    gcloud projects add-iam-policy-binding ${project_id} \
        --member="serviceAccount:${sa_name}@${project_id}.iam.gserviceaccount.com" \
        --role="roles/owner"
    gcloud projects add-iam-policy-binding ${project_id} \
        --member="serviceAccount:${sa_name}@${project_id}.iam.gserviceaccount.com" \
        --role="roles/iam.serviceAccountTokenCreator"
else
    echo "Creating Service Account and set permisions"
    gcloud iam service-accounts create ${sa_name}
    gcloud projects add-iam-policy-binding ${project_id} \
        --member="serviceAccount:${sa_name}@${project_id}.iam.gserviceaccount.com" \
        --role="roles/owner"
    gcloud projects add-iam-policy-binding ${project_id} \
        --member="serviceAccount:${sa_name}@${project_id}.iam.gserviceaccount.com" \
        --role="roles/iam.serviceAccountTokenCreator"
fi

# add workload identity
echo "Creating workload identity"
gcloud iam service-accounts add-iam-policy-binding ${sa_name}@${project_id}.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${project_id}.svc.id.goog[default/runner-account]"

# create bucket for terreform backend
if [[ $(gsutil ls -b gs://${bucket_name}) != "" ]]
then
    echo "Bucket ${bucket_name} already exists"
else
    echo "Creating bucket ${bucket_name}"
    gsutil mb gs://${bucket_name}
    gsutil versioning set on gs://${bucket_name}
    if [ $? -ne 0 ]; then echo "ERROR"; exit 1; fi
fi


list_of_secrets=$(gcloud secrets list --filter="name:runner_gh_token")
if [[ ${list_of_secrets} != "" ]]
then
    echo "Secret runner_gh_token exists, add new version"
    echo "${gh_token}" | gcloud secrets versions add "runner_gh_token" \
        --data-file=-
else
    echo "Secret runner_gh_token not exists, creating"
    echo "${gh_token}" | gcloud secrets create "runner_gh_token" \
        --data-file=-
fi

gcloud secrets add-iam-policy-binding "runner_gh_token" \
            --member="serviceAccount:${sa_name}@${project_id}.iam.gserviceaccount.com" \
            --role='roles/secretmanager.admin'

# auth to gcr in docker
gcloud auth configure-docker -q

# build runner app image
docker build -t gcr.io/${project_id}/runner-application ./runner-app/.
docker push gcr.io/${project_id}/runner-application

# build airee base app image
docker build -t gcr.io/${project_id}/airee-base ./airee-base/.
docker push gcr.io/${project_id}/airee-base

# create k8m manifest
k8s_main=$(cat ./k8s-yaml-files/runner-statefulset.yaml \
    | sed "s/{{PROJECT_ID}}/${project_id}/g" \
    | sed "s/{{GH_ORGANIZATION}}/${gh_org}/g" \
    | sed "s/{{GHR_LABELS}}/${ghr_labels}/g" \
    | sed "s/{{RUNNER_SA}}/${sa_name}@${project_id}.iam.gserviceaccount.com/g" \
    | sed "s/{{REPLICA_NUM}}/${replica_num}/g")

echo "$k8s_main"

gcloud container clusters get-credentials ${runner_cluster_name} --region ${gke_region}

# implement runner
echo "${k8s_main}" | kubectl apply --cluster gke_${project_id}_${gke_region}_${runner_cluster_name} -f -

exit 0