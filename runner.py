#!/usr/bin/env python2

import os
import psutil
import re
import shlex
import signal
import socket
import subprocess
import sys
import time
import toml

# Docker recrets directory
secrets_dir = "/var/run/secrets"
gitlab_runner_config = "config.toml"

# Defaults
docker_image = 'docker:latest'
docker_volumes = '/var/run/docker.sock:/var/run/docker.sock'
runner_executor = 'docker'

class GracefulKiller:
    kill_now = False

    def __init__(self):
        signal.signal(signal.SIGINT, self.exit_gracefully)
        signal.signal(signal.SIGTERM, self.exit_gracefully)

    def exit_gracefully(self, signum, frame):
        self.kill_now = True

# Returns the unique runner token from config.toml
def get_token(config_file):
    #token=$(grep token "/etc/gitlab-runner/config.toml" | awk '{print $3}' | tr -d '"')
    pass

# Runner term handler
# Unregisters the runner and sends SIGTERM to the process
def term_handler(subprocess, server, token):
    if subprocess.pid != 0:
        subprocess.terminate()
        subprocess.wait()

    cli = "gitlab runner unregister -u " + server + " -t " + token

if __name__ == "__main__":
    killer = GracefulKiller()

    url_match = re.match(r'https?://', os.environ['GITLAB_SERVER'])

    # Set Gitlab server URL
    gitlab_server = os.environ['GITLAB_SERVER'] if url_match else 'http://' + os.environ['GITLAB_SERVER']

    # Set default environment variables if they're not set
    os.environ['DOCKER_IMAGE'] = docker_image if 'DOCKER_IMAGE' not in os.environ else os.environ.get('DOCKER_IMAGE')
    os.environ['DOCKER_VOLUMES'] = docker_volumes if 'DOCKER_VOLUMES' not in os.environ else os.environ.get('DOCKER_VOLUMES')
    os.environ['RUNNER_EXECUTOR'] = runner_executor if 'DOCKER_EXECUTOR' not in os.environ else os.environ.get('DOCKER_EXECUTOR')

    # Spawn a process to register the runner
    # This also creates the runner config file at "/etc/gitlab-runner/config.toml"
    """runner = subprocess.Popen(
        shlex.split("gitlab-runner register -n -u " + gitlab_server),
        env=os.environ.copy()
    )"""

    gitlab_runner_username = 'gitlab-runner'
    gitlab_runner_home = '/home/' + gitlab_runner_username

    # Spawn a process to register the runner
    """multi_runner = subprocess.Popen(
        shlex.split(
            "gitlab-ci-multi-runner run --user=" + gitlab_runner_username + " --working-directory=" + gitlab_runner_home
        ),
        env=os.environ.copy()
    )"""

    # Parse config.toml and add in some extra settings
    config = toml.load(gitlab_runner_config)
    listen_port = 8093

    config['session_server'] = {
        'listen_address': '0.0.0.0:' + str(listen_port),
        'advertise_address': socket.gethostname() + ":" + str(listen_port),
        'session_timeout': 1800
    }

    # Write out the new config file.
    with open(gitlab_runner_config, "w") as f:
        toml.dump(config, f)

    # Loop forever until killed
    while True:
        time.sleep(1)

    #    try:
    #        outs, errs = multi_runner.communicate(timeout=15)
    #    except TimeoutExpired:
    #        proc.kill()
    #        outs, errs = proc.communicate()

        if killer.kill_now:
            break
