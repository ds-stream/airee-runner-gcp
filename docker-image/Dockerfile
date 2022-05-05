FROM ubuntu:20.04

#runner configuration
#PAT_TOKEN airee.app.1@dsstream.com, name: GithubActionsDsAirKube noexpirationdate
ENV PAT_TOKEN ""
ENV RUNNER_NAME ""
ENV ORGANIZATION ""
ENV REPO_PROJECT ""
#ENV REPO_URL https://github.com/${ORGANIZATION}/${REPO_PROJECT}
ENV REPO_URL https://github.com/${ORGANIZATION}
ENV RUNNER_LABELS azzure,airflow 
ENV RUNNER_VERSION 2.291.1
ENV RUNNER_PATH /etc/actions-runner
ENV SERVICE_ACCOUNT github-runner

ENV BINARY_VERSION actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
ENV URL_BINARY_VERSION https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

#install necessary tools and docker 
RUN apt update \
    && apt install jq curl apt-transport-https ca-certificates software-properties-common -y \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable" \
    && apt install docker-ce -y

##install gcloud
RUN apt install apt-transport-https ca-certificates gnupg -y \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" >> /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
    && apt update -y && apt install google-cloud-cli -y

#install terraform
RUN apt install -y gnupg \
    && curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - \
    && apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    && apt update -y && apt install terraform -y

#install kubectl
RUN apt-get update -y && apt-get upgrade -y && apt-get install kubectl -y

#create tech user
RUN adduser --disabled-password --gecos "" ${SERVICE_ACCOUNT}
RUN usermod -aG docker ${SERVICE_ACCOUNT}

#main app directory
RUN mkdir -p ${RUNNER_PATH}
WORKDIR ${RUNNER_PATH}

#extract runner
RUN curl -o ${BINARY_VERSION} -L ${URL_BINARY_VERSION} \
    && tar xzf ${BINARY_VERSION} && rm ${BINARY_VERSION} \
    && chown -R ${SERVICE_ACCOUNT} ${RUNNER_PATH}

#copy files
COPY ./start.sh .

#install runner dependencies
RUN ${RUNNER_PATH}/bin/installdependencies.sh

#connect runner to repository and launch app
USER ${SERVICE_ACCOUNT}
ENTRYPOINT ./start.sh
