#!/bin/sh

TAGS=${TAGS:-exporter}
TIMEOUT=${TIMEOUT:-60}
PREFIX=${PREFIX:-CONSUL_EXPORT}
CONSUL_AGENT_API_PORT=${CONSUL_AGENT_API_PORT:-'8500'}

while true; do
    docker_ps=$(timeout 10 docker ps -q)
    if [ $? -gt 0 ]; then
        logger -p local0.Error -s -t local-registrator "local-registrator failed to connect to docker-socket, exiting! (INFRA-3356)"
        exit 1
    fi
    CONSUL_SERVICES=$(curl -s --connect-timeout 10 --max-time 20 http://127.0.0.1:${CONSUL_AGENT_API_PORT}/v1/agent/services)
    echo "$docker_ps" | while read ID
    do
        for ENV in $(timeout -t 10 docker inspect "$ID" --format '{{range .Config.Env}}{{println .}}{{end}}')
        do
            if [ $? -gt 0 ]; then
                logger -p local0.Error -s -t local-registrator "local-registrator failed to connect to docker-socket, exiting! (INFRA-3356)"
                exit 1
            fi
            VAR=$(echo "$ENV" | awk -F= '{print $1}')
            VAL=$(echo "$ENV" | awk -F= '{print $2}')

            if [ "${VAR:0:${#PREFIX}}" == "$PREFIX" ]; then
                SERVICE=$(echo "$VAR" | awk -F_ '{print tolower($3)}')

                if echo "$CONSUL_SERVICES" | jq 'keys' | grep -q "${HOSTNAME}:${SERVICE}:${VAL}"; then
                    continue
                fi
                curl -s --connect-timeout 10 --max-time 20 -H "Content-Type: application/json" -X PUT \
                    -d "{\"ID\":\"${HOSTNAME}:${SERVICE}:${VAL}\",\"Name\":\"${SERVICE}\",\"Tags\":[\"${TAGS}\"],\"Port\":${VAL},\"Check\":{\"tcp\":\"localhost:${VAL}\",\"Interval\":\"10s\",\"deregister_critical_service_after\":\"1m\"}}" \
                    "http://127.0.0.1:${CONSUL_AGENT_API_PORT}/v1/agent/service/register"
            fi
        done
    done

    sleep ${TIMEOUT}
done
