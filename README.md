# runner-container

Github-action runner container designed for airee project.
The yaml file allows you to create a kubernetes deployment object which contains two containers in one pod.
The first container launches a github action runner and the second container runs a daemon docker.
They cooperate with each other and therefore the runner is able to run docker containers while executing CI/CD pipelines.

In order to make it works you should follow these steps:
- Create GCP service account and generate keys. We need a service account to set up an airee cluster in GCP.
https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating

- Enable GCP APIs: Cloud SQL Admin API, Cloud Asset API, Cloud Storage API 

- Grant "owner" and "service sccount token creator" roles for the service account. 
Creating tokens is required while creating state terraform files in the bucket.

- Transfer the private key to your kubernetes cluster. CI/CD pipeline will use this key to configure GCP connection.

#post service account keys

Pattern: ```kubectl create secret generic json --from-file=key.json=./__path_to_generated_file__.json```

Example: ```kubectl create secret generic json --from-file=key.json=./key.json```

- Generate PAT token which allows to read runner tokens.
```Click your profile on the top right corner / Settings / Developer settings / Personal acces tokens / Generate new token.``` 
Select the required permissions and save the PAT token as a secret in Kubernetes by putting the value in the token.yaml file. 

```kubectl apply -f k8s-yaml-files/token.yaml```

- Build docker image for runner

#create docker image

```cd docker-image```

Pattern: ```docker build . -t __container_registry__/__container_name__```

Example: ```docker build . -t airflowkubernetesui.azurecr.io/runner-container ```

- Push this image to registry

#authorization with registry via temporary token

#run the code below in azzure terminal

Pattern: ```az acr login -n __container_registry__ --expose-token```

Example: ```az acr login -n airflowkubernetesui.azurecr.io --expose-token```

#run the code below in your local terminal

Pattern: ```docker login __container_registry__ --username 00000000-0000-0000-0000-000000000000 --password __paste_the_token_here__```

Example: ```docker login airflowkubernetesui.azurecr.io --username 00000000-0000-0000-0000-000000000000 --password KoozhesGeorboybNiOvDupgoDracfepHahitnuppOsjajwedgeyptecTharHoosOytkungAbMymyevro```

#push image to registry

Pattern: ```docker push __container_registry__/__container_name__```

Example: ```docker push airflowkubernetesui.azurecr.io/runner-container```

- Configure the appropriate connection between your kubernetes cluster and the cloud registry. Thanks to this, your pod has no problems downloading images.

Pattern: ```az aks update -n __kubernetes_cluster_name__ -g __group_resources__ --attach-acr __container_registry__```

Example: ```az aks update -n airflow_kubernetes_ui_test -g airflow_kubernetes_ui --attach-acr airflowkubernetesui```

- Authorize kubectl

Pattern: ```az aks get-credentials --resource-group __resource_group__ --name __kubernetes_cluster_name__```

Example: ```az aks get-credentials --resource-group airflow_kubernetes_ui --name airflow_kubernetes_ui_test```

- Create deployment
```kubectl apply -f k8s-yaml-files/runner-deployment.yaml```
