# velocityorg/docker-gitlab-runner
https://hub.docker.com/r/velocityorg/docker-gitlab-runner/

Gitlab runner that uses Docker swarm with S3/Minio distributed cache server support

## Supported tags and respective `Dockerfile` links
- [`latest` (*latest/Dockerfile*)](https://github.com/velocityorg/docker-gitlab-runner/blob/master/latest/Dockerfile)

## Required environment variables
- `CI_SERVER_URL` Hostname/IP address:port of your Gitlab server
- `REGISTRATION_TOKEN` Runner authentication token supplied by Gitlab (`Settings` => `Runners`)
- `S3_SERVER_ADDRESS` Hostname/IP address:port of your Amazon S3 or Minio server
- `S3_ACCESS_KEY` Amazon S3 or Minio access key
- `S3_SECRET_KEY` Amazon S3 or Minio secret key

## Example Docker swarm stack configuration

```
version: '3'

services:
    gitlab-runner:
        image: velocityorg/docker-gitlab-runner:latest
        environment:
            - CI_SERVER_URL=<Gitlab server URL (hopefully with https)>
            - REGISTRATION_TOKEN=<Runner registration token supplied by Gitlab>
            - S3_SERVER_ADDRESS="127.0.0.1:9000"
            - S3_ACCESS_KEY="<access key>"
            - S3_SECRET_KEY="<secret key>"
        volumes:
            - '/var/run/docker.sock:/var/run/docker.sock'
        networks:
            - gitlab_ci_net
        deploy:
            mode: global
            placement:
                constraints: [node.role == worker]

networks:
  gitlab_ci_net:
```
