#!/bin/bash

set -x

# SETTINGS #############################################################

# Directory where Docker secrets are stored
secrets_dir="/var/run/secrets"

# Other vars
# You shouldn't change these unless you know what you're doing
pid=0
token=()

# ENVIRONMENT CHECK ####################################################

if ! [[ ${GITLAB_SERVER} =~ ^https?:// ]]; then
    gitlab_server="http://${GITLAB_SERVER}"
else
    gitlab_server="${GITLAB_SERVER}"
fi

# Set default environment vars/runner options

if [[ -z ${DOCKER_IMAGE} ]]; then
    export DOCKER_IMAGE="docker:latest"
fi

if [[ -z ${DOCKER_VOLUMES} ]]; then
    export DOCKER_VOLUMES="/var/run/docker.sock:/var/run/docker.sock"
fi

if [[ -z ${RUNNER_EXECUTOR} ]]; then
    export RUNNER_EXECUTOR="docker"
fi

########################################################################
#                                                                      #
#                              FUNCTIONS                               #
#                                                                      #
########################################################################

# Gets runner token from config file
# This is necessary when unregistering the runner
function get_token () {
    token=$(grep token "/etc/gitlab-runner/config.toml" | awk '{print $3}' | tr -d '"')
}

# SIGTERM-handler
# Unregisters Gitlab on process SIGTERM
function term_handler() {
    if [[ $pid -ne 0 ]]; then
        kill -SIGTERM "$pid"
        wait "$pid"
    fi

    gitlab-runner unregister -u ${gitlab_server} -t ${token}

    exit 143; # 128 + 15 -- SIGTERM
}

########################################################################
#                                                                      #
#                             SCRIPT START                             #
#                                                                      #
########################################################################

# Docker secrets
if [[ -r "${secrets_dir}/gitlab_registration_token" ]]; then
    export REGISTRATION_TOKEN=$(<"${secrets_dir}/gitlab_registration_token")
fi

if [[ -r "${secrets_dir}/s3_access_key" ]]; then
    export CACHE_S3_ACCESS_KEY=$(<"${secrets_dir}/s3_access_key")
fi

if [[ -r "${secrets_dir}/s3_secret_key" ]]; then
    export CACHE_S3_SECRET_KEY=$(<"${secrets_dir}/s3_secret_key")
fi

# Register runner in non-interactive mode
# All options are set via environment variables
gitlab-runner register -n -u ${gitlab_server}

# Note: /etc/gitlab-runner/config.toml is dynamically generated from the arguments specified during runner registration

# Set runner token in $token
#token=$(grep token "/etc/gitlab-runner/config.toml" | awk '{print $3}' | tr -d '"')
get_token

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; term_handler' SIGTERM

# run multi-runner
gitlab-ci-multi-runner run --user=gitlab-runner --working-directory=/home/gitlab-runner & pid="$!"

# Wait forever
# When this process ends, send SIGTERM to stop the runner
while true; do
    tail -f /dev/null & wait ${!}
done
