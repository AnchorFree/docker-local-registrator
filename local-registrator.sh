#!/bin/sh

TAGS=${TAGS:-exporter}
TIMEOUT=${TIMEOUT:-60}
PREFIX=${PREFIX:-CONSUL_EXPORT}

while true; do
    timeout -t 10 docker ps -q | while read ID
    do
        for ENV in $(timeout -t 10 docker inspect "$ID" --format '{{range .Config.Env}}{{println .}}{{end}}')
        do
            VAR=$(echo "$ENV" | awk -F= '{print $1}')
            VAL=$(echo "$ENV" | awk -F= '{print $2}')

            if [ "${VAR:0:${#PREFIX}}" == "$PREFIX" ]; then
                SERVICE=$(echo "$VAR" | awk -F_ '{print tolower($3)}')

                curl -s --connect-timeout 10 --max-time 20 -H "Content-Type: application/json" -X PUT \
                    -d "{\"ID\":\"${SERVICE}:${VAL}\",\"Name\":\"${SERVICE}\",\"Tags\":[\"${TAGS}\"],\"Port\":${VAL},\"Check\":{\"tcp\":\"localhost:${VAL}\",\"Interval\":\"10s\",\"deregister_critical_service_after\":\"1m\"}}" \
                    'http://127.0.0.1:8500/v1/agent/service/register'
            fi
        done
    done

    sleep ${TIMEOUT}
done
