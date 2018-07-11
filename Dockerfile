FROM gitlab/gitlab-runner

MAINTAINER Steven Cook <scook@velocity.org>

ADD runner.sh /runner.sh
RUN chmod +x /runner.sh

ENTRYPOINT ["/runner.sh"]
