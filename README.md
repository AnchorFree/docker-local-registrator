# local-registrator
Simple stript with is run as container and periodicaly look for special enviroment variable and register service in local consul-agent.

# Special environment variable
This container look at config section of docker inspect for all running containers and find cpecial envvar.
Special variable must have prefix of $PREFIX or 'CONSUL_EXPORT_' by default.
Word after this prefix will lowercase and become the name of a service.
Value of this variable treated as tcp port and service check point to that port.

# Requirements
- container must have access to docker.sock
-v /var/run/docker.sock:/var/run/docker.sock
- network access to consul-agent API
