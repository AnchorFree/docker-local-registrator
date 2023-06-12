FROM docker:24.0.2

RUN apk add curl jq --update-cache

COPY local-registrator.sh /local-registrator.sh

ENTRYPOINT ["/local-registrator.sh"]
