# velocityorg/docker-gitlab-runner
https://hub.docker.com/r/velocityorg/docker-gitlab-runner/

Gitlab runner that uses Docker swarm with S3/Minio distributed cache server support

## Supported tags and respective `Dockerfile` links
- [`latest` (*tags/latest/Dockerfile*)](https://github.com/velocityorg/docker-gitlab-runner/blob/master/tags/latest/Dockerfile)

## Required environment variables
- `GITLAB_HOST` Hostname/IP address:port of your Gitlab server
- `S3_HOST` Hostname/IP address:port of your Amazon S3 or Minio server

## Required Docker secrets

This setup uses Docker secrets to store and retrieve sensitive data. Before deploying your stack, make sure the following secrets exist:

- `gitlab_access_token` Runner authentication token supplied by Gitlab (`Settings` => `Runners`)
- `s3_access_key` Amazon S3 or Minio access key
- `s3_secret_key` Amazon S3 or Minio secret key

The secrets must be named above, as the runner shell script looks for files with these names in the running container.

You can create these secrets by running the following commands on your swarm manager node:
- `echo "Gitlab access token goes here" | docker secret create gitlab_access_token -`
- `echo "S3 access key goes here" | docker secret create s3_access_key -`
- `echo "S3 secret key goes here" | docker secret create s3_secret_key -`

File-based secrets may instead be used, but this is not recommended if you store your swarm setup in a git repository.

## Example Docker swarm stack configuration

```
version: '3'

services:
    gitlab-runner:
        image: velocityorg/docker-gitlab-runner:latest
        environment:
            - GITLAB_HOST="https://my.cool.gitlab.server.com"
            - S3_HOST="127.0.0.1:9000"
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
