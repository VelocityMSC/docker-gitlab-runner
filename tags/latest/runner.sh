#!/usr/bin/env bash

set -x

# Required Gitlab runner options

if ! [[ ${GITLAB_HOST} =~ ^https?:// ]]; then
    gitlab_host=http://${GITLAB_HOST}
else
    gitlab_host=${GITLAB_HOST}
fi

# We utilize Docker secrets for sensitive info here
docker_secrets_dir="/var/run/secrets"
gitlab_access_token=$(<"${docker_secrets_dir}/gitlab_access_token")
s3_access_key=$(<"${docker_secrets_dir}/s3_access_key")
s3_secret_key=$(<"${docker_secrets_dir}/s3_secret_key")

# Other variables
pid=0
token=()

# SIGTERM-handler
term_handler() {
    if [[ $pid -ne 0 ]]; then
        kill -SIGTERM "$pid"
        wait "$pid"
    fi

    gitlab-runner unregister -u ${gitlab_host} -t ${token}

    exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; term_handler' SIGTERM

# TODO: Make runner options a bit more dynamic


# register runner
yes '' | gitlab-runner register \
    -u "${gitlab_host}" \
    -r "${gitlab_access_token}" \
    --executor "docker" \
    --docker-image "docker:latest" \
    --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
    --name "runner" \
    --output-limit 20480 \
    --tag-list "docker" \
    --cache-type "s3" \
    --cache-s3-server-address ${S3_HOST} \
    --cache-s3-access-key ${s3_access_key} \
    --cache-s3-secret-key ${s3_secret_key} \
    --cache-s3-bucket-name "runner" \
    --cache-s3-insecure true \
    --cache-cache-shared true

# /etc/gitlab-runner/config.toml is dynamically generated from the arguments specified during runner registration

# Assign runner token
# Old line was commented out, because we don't kill cats. :)
#token=$(cat /etc/gitlab-runner/config.toml | grep token | awk '{print $3}' | tr -d '"')
token=$(grep token "/etc/gitlab-runner/config.toml" | awk '{print $3}' | tr -d '"')

# run multi-runner
gitlab-ci-multi-runner run --user=gitlab-runner --working-directory=/home/gitlab-runner & pid="$!"

# wait forever
while true; do
    tail -f /dev/null & wait ${!}
done
