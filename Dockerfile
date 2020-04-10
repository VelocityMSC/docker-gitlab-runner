FROM gitlab/gitlab-runner:v12.6.0
MAINTAINER Steven Cook <scook@velocity.org>

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install python python-toml

COPY runner.sh /

RUN chmod +x /runner.sh

ENTRYPOINT /runner.sh
