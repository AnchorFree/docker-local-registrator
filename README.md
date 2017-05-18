# local-registrator
Simple stript with is run as container and periodicaly look for special enviroment variable and register service in local consul-agent.

# Requirements
- container must have access to docker.sock
-v /var/run/docker.sock:/var/run/docker.sock
- network access to consul-agent API
