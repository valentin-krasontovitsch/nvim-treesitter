FROM python AS base

RUN pip install requests

FROM alpine
RUN apk add openssh-client
CMD ["/usr/bin/sh"]
