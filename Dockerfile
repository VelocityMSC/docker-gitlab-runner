FROM gitlab/gitlab-runner

MAINTAINER Steven Cook <scook@velocity.org>

COPY runner.sh /
RUN chmod +x /runner.sh

CMD /runner.sh
