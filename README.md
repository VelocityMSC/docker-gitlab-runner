# Velocity.org Gitlab Runner 12.6.0
https://hub.docker.com/r/velocityorg/docker-gitlab-runner/

Gitlab multi-runner stack deployable on a Docker swarm

## Supported tags and `Dockerfile` links
- [`latest` (*latest/Dockerfile*)](https://github.com/velocityorg/docker-gitlab-runner/blob/master/latest/Dockerfile)

TODO: Support multiple runner versions other than "latest".

## Environment Variables

The Gitlab runner application supports its own environment variables for configuration, so any of these that are set via `docker run -e ...` or in your compose file will be passed through to the `gitlab-runner` binary.

The only environment variable that must be specified is `GITLAB_SERVER` with the full URL to your Gitlab instance, including the **https** scheme. This environment variable `CI_SERVER_URL` is normally passed here, but we felt that `GITLAB_SERVER` was a little more "informational". In the future, the runner script will probably support both.

### Required Variables

- `GITLAB_SERVER`: Hostname/IP address:port of your Gitlab server, including the **https** scheme. You are using HTTPS, right?

### Other Environment Variables

Please see the file `syntax.md` for other environment variables that can be passed to the runner.

## Docker secrets

This setup uses Docker secrets to store and retrieve sensitive data. The following secrets are supported:

- `gitlab_access_token` Runner authentication token supplied by Gitlab (In Gitlab admin: `Settings` => `Runners`)
- `s3_access_key` (optional) Amazon S3 (or compatible) access key
- `s3_secret_key` (optional) Amazon S3 (or compatible) secret key

The secrets must be named exactly as shown; the runner shell script looks for matching filenames in the usual `/var/run/secrets` path.

You can create these secrets by running the following commands on any swarm manager node:
- `echo "your_gitlab_access_token" | docker secret create gitlab_access_token -`
- `echo "your_s3_access_key_here" | docker secret create s3_access_key -`
- `echo "your_s3_secret_key_here" | docker secret create s3_secret_key -`

File-based secrets may instead be used, but this is not recommended if you store your stack setup in a git repository.

### Secrets Without a Swarm

If you want to use this image without a Docker swarm, then you cannot use Docker secrets. An alternative in this mode is to create a `docker-compose.override.yaml` file and specif sensitive data that way. This override file should NOT be committed to any version control system. An example compose override file could look like the following:

## Example Docker swarm stack configuration

```
version: '3.7'

services:
    gitlab-runner:
        image: velocityorg/docker-gitlab-runner:latest
        environment:
            - GITLAB_SERVER=https://my.cool.gitlab.server.com
        volumes:
            - '/var/run/docker.sock:/var/run/docker.sock'
        networks:
            - gitlab_ci_net
        secrets:
            - gitlab_access_token
            - s3_access_key
            - s3_secret_key
        deploy:
            mode: global
            placement:
                constraints: [node.role == worker]

secrets:
    gitlab_access_token:
        external: true
    s3_access_key:
        external: true
    s3_secret_key:
        external: true

networks:
  gitlab_ci_net:
```

NOTE: If you plan to use Docker secrets, then Your stack configuration file **must** at least specify `version: 3.1`, as Docker secrets were not available until that version. This also means your installed Docker version must be at least **v1.13.1**.
