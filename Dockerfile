FROM gitlab/gitlab-runner:v11.3.1

MAINTAINER Steven Cook <scook@velocity.org>

RUN apt-get update \
    && apt-get upgrade \
    && apt-get install python python-toml

COPY runner.sh /
COPY runner.oy /

RUN chmod +x /runner.sh && chmod +x /runner.py

ENTRYPOINT /runner.sh
