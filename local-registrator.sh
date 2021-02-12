#!/bin/sh

TAGS=${TAGS:-exporter}
TIMEOUT=${TIMEOUT:-60}
PREFIX=${PREFIX:-CONSUL_EXPORT}
CONSUL_AGENT_API_PORT=${CONSUL_AGENT_API_PORT:-'8500'}

logger -p local0.Debug -s -t local-registrator "DEBUG TAGS ${TAGS}"
logger -p local0.Debug -s -t local-registrator "DEBUG TIMEOUT ${TIMEOUT}"
logger -p local0.Debug -s -t local-registrator "DEBUG PREFIX ${PREFIX}"
logger -p local0.Debug -s -t local-registrator "DEBUG CONSUL_AGENT_API_PORT ${CONSUL_AGENT_API_PORT}"

while true; do
    logger -p local0.Debug -s -t local-registrator "Iteration started"
    docker_ps=$(timeout -t 10 docker ps -q)
    logger -p local0.Debug -s -t local-registrator "DEBUG docker_ps: ${docker_ps}"
    if [ $? -gt 0 ]; then
        logger -p local0.Error -s -t local-registrator "local-registrator failed to connect to docker-socket, exiting! (INFRA-3356)"
        exit 1
    fi
    CONSUL_SERVICES=$(curl -s --connect-timeout 10 --max-time 20 http://127.0.0.1:${CONSUL_AGENT_API_PORT}/v1/agent/services)
    logger -p local0.Debug -s -t local-registrator "DEBUG CONSUL_SERVICES: ${CONSUL_SERVICES}"
    echo "$docker_ps" | while read ID
    do
        logger -p local0.Debug -s -t local-registrator "DEBUG ID: ${ID}"
        logger -p local0.Debug -s -t local-registrator "DEBUG ENVs: $(timeout -t 10 docker inspect "$ID" --format '{{range .Config.Env}}{{println .}}{{end}}')"
        for ENV in $(timeout -t 10 docker inspect "$ID" --format '{{range .Config.Env}}{{println .}}{{end}}')
        do
            logger -p local0.Debug -s -t local-registrator "DEBUG ENV: ${ENV}"
            if [ $? -gt 0 ]; then
                logger -p local0.Error -s -t local-registrator "local-registrator failed to connect to docker-socket, exiting! (INFRA-3356)"
                exit 1
            fi
            VAR=$(echo "$ENV" | awk -F= '{print $1}')
            VAL=$(echo "$ENV" | awk -F= '{print $2}')
            logger -p local0.Debug -s -t local-registrator "DEBUG VAR: ${VAR}"
            logger -p local0.Debug -s -t local-registrator "DEBUG VAL: ${VAL}"
            if [ "${VAR:0:${#PREFIX}}" == "$PREFIX" ]; then
                logger -p local0.Debug -s -t local-registrator "DEBUG PREFIX true"
                SERVICE=$(echo "$VAR" | awk -F_ '{print tolower($3)}')
                logger -p local0.Debug -s -t local-registrator "DEBUG SERVICE: ${SERVICE}"
                if echo "$CONSUL_SERVICES" | jq 'keys' | grep -q "${HOSTNAME}:${SERVICE}:${VAL}"; then
                    logger -p local0.Debug -s -t local-registrator "DEBUG continue true"
                    continue
                fi
                logger -p local0.Debug -s -t local-registrator "DEBUG going to register the service above"
                curl -s --connect-timeout 10 --max-time 20 -H "Content-Type: application/json" -X PUT \
                    -d "{\"ID\":\"${HOSTNAME}:${SERVICE}:${VAL}\",\"Name\":\"${SERVICE}\",\"Tags\":[\"${TAGS}\"],\"Port\":${VAL},\"Check\":{\"tcp\":\"localhost:${VAL}\",\"Interval\":\"10s\",\"deregister_critical_service_after\":\"1m\"}}" \
                    "http://127.0.0.1:${CONSUL_AGENT_API_PORT}/v1/agent/service/register"
            fi
        done
    done
    logger -p local0.Debug -s -t local-registrator "DEBUG sleep for ${TIMEOUT}"
    sleep ${TIMEOUT}
done
