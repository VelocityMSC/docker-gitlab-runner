FROM gitlab/gitlab-runner:v11.3.1

MAINTAINER Steven Cook <scook@velocity.org>

COPY runner.sh /
RUN chmod +x /runner.sh

ENTRYPOINT /runner.sh
