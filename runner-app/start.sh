#!/bin/bash
cd ${RUNNER_PATH}

# get PAT_TOKEN from secret menager
pat_token_version=$(gcloud secrets versions list runner_gh_token --limit=1 --sort-by=name --format="get(name)")
PAT_TOKEN=$(gcloud secrets versions access ${pat_token_version})

#if ((`echo ${REPO_PROJECT} | wc -m` > 1 )); then
#TOKEN=$(curl -sX POST -H "Authorization: token ${PAT_TOKEN}" https://api.github.com/repos/${ORGANIZATION}/${REPO_PROJECT}/actions/runners/registration-token | jq .token --raw-output)
#else
TOKEN=$(curl -sX POST -H "Authorization: token ${PAT_TOKEN}" https://api.github.com/orgs/${ORGANIZATION}/actions/runners/registration-token | jq .token --raw-output)
#fi

./config.sh --disableupdate --url ${REPO_URL} --token ${TOKEN} --name ${RUNNER_NAME} --runnergroup Default --labels ${RUNNER_LABELS} --work _work --replace && ./run.sh
