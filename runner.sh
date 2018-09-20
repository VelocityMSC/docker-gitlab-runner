#!/usr/bin/env bash

set -x

# SETTINGS #############################################################

# Directory where Docker secrets are stored
secrets_dir="/var/run/secrets"

# Other vars
# You shouldn't change these unless you know what you're doing
pid=0
token=()

# ENVIRONMENT CHECK ####################################################

if [[ -n ${CI_SERVER_URL} ]]; then
    # Fix Gitlab server URL by prepending a scheme if none specified
    if ! [[ ${CI_SERVER_URL} =~ "https?://" ]]; then
        CI_SERVER_URL="http://${CI_SERVER_URL}"
    fi
else
    exit 1
fi

# Set default environment vars/runner options

[[ -z "${DOCKER_IMAGE}" ]] && DOCKER_IMAGE="docker:latest"
[[ -z "${DOCKER_VOLUMES}" ]] && DOCKER_VOLUMES="/var/run/docker.sock:/var/run/docker.sock"
[[ -z "${RUNNER_EXECUTOR}" ]] && RUNNER_EXECUTOR="docker"

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

    gitlab-runner unregister -u ${CI_SERVER_URL} -t ${token}

    exit 143; # 128 + 15 -- SIGTERM
}

########################################################################
#                                                                      #
#                             SCRIPT START                             #
#                                                                      #
########################################################################

# Docker secrets
[[ -r "${secrets_dir}/gitlab_access_token" ]] && REGISTRATION_TOKEN=$(<"${secrets_dir}/gitlab_registration_token")
[[ -r "${secrets_dir}/s3_access_key" ]] && S3_ACCESS_KEY=$(<"${secrets_dir}/s3_access_key")
[[ -r "${secrets_dir}/s3_secret_key" ]] && S3_SECRET_KEY=$(<"${secrets_dir}/s3_secret_key")

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; term_handler' SIGTERM

# Register runner in non-interactive mode
# All options are set via environment variables
gitlab-runner register -n

# Note: /etc/gitlab-runner/config.toml is dynamically generated from the arguments specified during runner registration

# Set runner token in $token
#token=$(grep token "/etc/gitlab-runner/config.toml" | awk '{print $3}' | tr -d '"')
get_token

# run multi-runner
gitlab-ci-multi-runner run --user=gitlab-runner --working-directory=/home/gitlab-runner & pid="$!"

# Wait forever
# When this process ends, send SIGTERM to stop the runner
while true; do
    tail -f /dev/null & wait ${!}
done
