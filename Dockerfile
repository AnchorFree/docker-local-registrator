FROM docker:24.0.5
# hadolint ignore=DL3003,SC1035,DL3019,DL3018
RUN apk add curl jq --update-cache

COPY local-registrator.sh /local-registrator.sh

ENTRYPOINT ["/local-registrator.sh"]
