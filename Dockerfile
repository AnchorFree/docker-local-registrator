FROM docker:24.0.2
# hadolint ignore=DL3003,SC1035,DL3019
RUN apk add curl jq --update-cache

COPY local-registrator.sh /local-registrator.sh

ENTRYPOINT ["/local-registrator.sh"]
