#!/bin/bash -e

SCRIPT="$( realpath "${0}" )"
SCRIPTPATH="$( dirname "${SCRIPT}" )"
REPO_FILE="${PWD}/repos.ls"
REPO_LIST=($(cat "${REPO_FILE}"))
BLACKDUCK_SCRIPT="../blackdk.sh"
BLACKDUCK_SCRIPT_PATH="$( dirname "$(readlink -f "${BLACKDUCK_SCRIPT}")" )"
BLACKDUCK_CREDS_PATH="../.creds"
BLACKDUCK_TAG="latest"
ECR="x.azurecr.io"

blackduck_script () {
    if [ -e "${BLACKDUCK_SCRIPT}" ]; then
        echo "Blackduck script already here"
    else
        echo "linking Blackduck script"
        ln -s "${BLACKDUCK_SCRIPT}" blackd.sh
    fi
}

repository_branch_pull () {
    for repo in "${REPO_LIST[@]}"
    do
        if [ -e "${repo}" ]; then
            echo "Repository: ${repo} already clonned"
        else
            echo "Clonning repository: ${repo}"
            git clone x@vs-ssh.visualstudio.com:v3/x/DigitalFactory/"${repo}"
        fi
        cd "${repo}"
        if git rev-parse --verify release >/dev/null 2>&1; then
            git checkout release
        elif git rev-parse --verify master >/dev/null 2>&1; then
            git checkout master
        elif git rev-parse --verify main >/dev/null 2>&1; then
            git checkout main
        else
            echo "The ${repo} don't have a release/master/main branch"
        fi
        echo "pulling repo:"
        git pull
        cd "${SCRIPTPATH}"
    done
}

repository_blackduck_scan () {
    az acr login -n abbdigitalaccelerator
    for repo in "${REPO_LIST[@]}"
    do
        cd "${repo}"
        if [ "${repo}" == "WB-Traefik" ]; then
                IMAGE_TAG="${BLACKDUCK_TAG}"
                #This condition is because the reponames are different on ACR
                DOCKER_IMG=$(echo "${repo}" | grep -E "^[A-Z]{2,}-[A-Za-z]+$" | awk -F'-' '{print tolower($2)}')
                echo "******* SCANNING REPOSITORY: ${repo} *******"
                ./blackd.sh -p "${repo}" -t "${BLACKDUCK_TAG}" -c "${BLACKDUCK_CREDS_PATH}" -d "${ECR}/${DOCKER_IMG}:${IMAGE_TAG}"
            elif [ "${repo}" == "WB-NatsServer" ]; then
                IMAGE_TAG="${BLACKDUCK_TAG}"
                DOCKER_IMG="nats"
                echo "******* SCANNING REPOSITORY: ${repo} *******"
                ./blackd.sh -p "${repo}" -t "${BLACKDUCK_TAG}" -c "${BLACKDUCK_CREDS_PATH}" -d "${ECR}/${DOCKER_IMG}:${IMAGE_TAG}"
            elif [ "${repo}" == "WB-Broker-MQTT" ]; then
                IMAGE_TAG="${BLACKDUCK_TAG}"
                DOCKER_IMG="broker"
                echo "******* SCANNING REPOSITORY: ${repo} *******"
                ./blackd.sh -p "${repo}" -t "${BLACKDUCK_TAG}" -c "${BLACKDUCK_CREDS_PATH}" -d "${ECR}/${DOCKER_IMG}:${IMAGE_TAG}"
            else
                echo "******* SCANNING REPOSITORY: ${repo} *******"
                ./blackd.sh -p "${repo}" -t "${BLACKDUCK_TAG}" -c "${BLACKDUCK_CREDS_PATH}" -y
        fi
        cd "${SCRIPTPATH}"
        echo "******* REPOSITORY ${repo} SCAN DONE *******"
    done 
}


blackduck_script
repository_branch_pull
repository_blackduck_scan
echo "FINISH!!!..."