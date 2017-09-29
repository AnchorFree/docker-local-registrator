FROM docker

RUN apk add curl jq --update-cache

COPY local-registrator.sh /local-registrator.sh

ENTRYPOINT ["/local-registrator.sh"]
