#!/bin/bash -e
yarn_analize_flag=
usage_flag=
blackDuckProjectName=
blackDuckDockerImage=
tag=

#reqs:
usage() {
    cat <<EOF

    Script used to run local blackduck test and send it to ABB Blackduck.
    Make .creds file, e.g.:
			url="https://x.app.blackduck.com"
			token="token_from_your_user"
    
    Usage:
        ${0} -h

        ${0} -p <ProjectName> -t <tag> <option>
        
    Options:
        -h                      Get this help.
        -p                      Project Name in Blackduck.
        -c                      Select creds file. Default= "${HOME}/.blackduck-creds" .
        -t                      Tag you will work on.
        -d                      Docker image mode.
        -y                      Yarn mode.

    e.g. blackd.sh -p "OptiFact\ Edge" -t "1.1.1" -c "${PWD}/.blackduck-creds" -y
    e.g. blackd.sh -p "OptiFact\ Edge" -t "1.1.1" -c "${PWD}/.blackduck-creds" -d "x.azurecr.io/nats-dev:2.3.2-29127"
    
EOF
}

install_java () {
    java --version
    if [ $? -eq 0 ]; then
        echo "java already installed"
    else
        echo "Installing Java-jdk"
        sudo apt install default-jdk
    fi
}

#This option --detect.tools.excluded=BINARY_SCAN should be removed when the feature is paid
docker_analize () {
    args="  --detect.docker.image=${blackDuckDockerImage} \
            --detect.tools.excluded=BINARY_SCAN"
    echo "${args}"
    blackduck_start
}

yarn_analize () {
    args="  --detect.python.path=/usr/bin/python3 \
            --detect.pip.path=/usr/bin/pip3 \
            --detect.blackduck.signature.scanner.copyright.search=true \
            --detect.blackduck.signature.scanner.license.search=true \
            --detect.blackduck.signature.scanner.snippet.matching=SNIPPET_MATCHING \
            --detect.detector.search.continue=true \
            --detect.impact.analysis.enabled=true \
            --detect.cleanup=false \
            --detect.detector.search.exclusion.defaults=false \
            --detect.detector.search.depth=20 \
            --detect.excluded.detector.types=NPM,LERNA \
            --detect.yarn.dependency.types.excluded=NONE \
            --detect.tools=ALL \
            --detect.excluded.directories.defaults.disabled=true \
            --logging.level.com.synopsys.integration=DEBUG  \
            --detect.binary.scan.file.path=docker-cleanup/docker-cleanup \
            --detect.blackduck.signature.scanner.individual.file.matching=ALL \
            --detect.project.codelocation.unmap=true #clean project version scans
    "
    blackduck_start
}

blackduck_start () {
    args
    install_java
    curl -s https://detect.synopsys.com/detect7.sh | bash -s --\
                  --blackduck.url="${blackDuckUrl}" \
                  --blackduck.api.token="${blackDuckApiToken}" \
                  --detect.project.name="${blackDuckProjectName}" \
                  --detect.project.version.name="${tag}" \
                  "${args}"
}

args() {
    if [ -z "${blackDuckUrl}" ] || [ -z "${blackDuckApiToken}" ]
    then
        echo "ERROR: you need to check .creds file, -h for help." >&2
        usage >&2
        exit 1
    fi
    if [ -z "${blackDuckProjectName}" ] || [ -z "${tag}" ]
    then
        echo "ERROR: at least one argument must be defined." >&2
        usage >&2
        exit 1
    fi
}

# Parse flags
while getopts :hp:t:c:d:y FLAG;
do
    case "${FLAG}" in
        h) usage_flag=true
           ;;
        p) blackDuckProjectName="${OPTARG}" ;;
        t) tag="${OPTARG}" ;;
        d)
          echo "ANALIZING DOCKER IMAGE: -${OPTARG}."
          blackDuckDockerImage="${OPTARG}"
          ;;
        y) yarn_analize_flag=true ;;
        c) CREDS_FILE="${OPTARG}" ;;
        # Handle Errors
        :)
          echo "${0}: ERROR: Must supply a value to -${OPTARG}." >&2
          usage_flag=true
          ;;
        ?)
          echo "${0}: ERROR: Invalid option: -${OPTARG}." >&2
          usage_flag=true
          ;;
    esac
done

if [ -z "${blackDuckDockerImage}" ] || [ "${yarn_analize_flag}" ] ; then
  usage >&2
fi

if [ "${usage_flag}" ]; then
  usage >&2
fi

if [ -z "$CREDS_FILE" ]; then
  CREDS_FILE="${HOME}/.blackduck-creds"
fi
. "${CREDS_FILE}"
blackDuckUrl="${url}"
blackDuckApiToken="${token}"

if [ -n "${blackDuckDockerImage}" ]; then
  docker_analize
fi

if [ "${yarn_analize_flag}" ]; then
  yarn_analize
fi

args