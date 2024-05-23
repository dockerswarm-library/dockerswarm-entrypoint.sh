#!/bin/bash
# See: https://github.com/dockerswarm-library/dockerswarm-entrypoint.sh/blob/main/dockerswarm-entrypoint.sh

entrypoint_log() {
    if [ -z "${DOCKERSWARM_ENTRYPOINT_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

# Get the IP addresses of the tasks of the service using DNS resolution
function dockerswarm_service_discovery() {
    local service_name=$1
    if [ -z "$service_name" ]; then
        echo "[dockerswarm_service_discovery]: command line is not complete, service name is required"
        return 1
    fi
    dig +short "tasks.${service_name}" | sort
}

# Get IP address using the Docker service network name instead of interface name
function dockerswarm_network_addr() {
    local network_name=$1
    if [ -z "$network_name" ]; then
        echo "[dockerswarm_network_addr]: command line is not complete, network name is required"
        return 1
    fi
    # Loop through assigned IP addresses to the host
    for ip in $(hostname -i); do
        # Query the PTR record for the IP address
        local ptr_record=$(host "$ip" | cut -d ' ' -f 5)
        # If the PTR record is empty, skip to the next IP address
        if [ -z "$ptr_record" ]; then
            continue
        fi
        # Filter the PTR record to get the network name
        local service_network=$(echo "$ptr_record" | cut -d '.' -f 4)
        # Check if the network name matches the input network name
        if [[ "$service_network" == *"$network_name" ]]; then
            echo "$ip"
            return
        fi
    done

    echo "[dockerswarm_network_addr]: can't find network '$network_name'"
    return 2
}

export DOCKERSWARM_ENTRYPOINT=true
export DOCKERSWARM_STARTUP_DELAY=${DOCKERSWARM_STARTUP_DELAY:-15}
echo "Enable Docker Swarm Entrypoint..."

# Docker Swarm service template variables
#  - DOCKERSWARM_SERVICE_ID={{.Service.ID}}
#  - DOCKERSWARM_SERVICE_NAME={{.Service.Name}}
#  - DOCKERSWARM_NODE_ID={{.Node.ID}}
#  - DOCKERSWARM_NODE_HOSTNAME={{.Node.Hostname}}
#  - DOCKERSWARM_TASK_ID={{.Task.ID}}
#  - DOCKERSWARM_TASK_NAME={{.Task.Name}}
#  - DOCKERSWARM_TASK_SLOT={{.Task.Slot}}
#  - DOCKERSWARM_STACK_NAMESPACE={{ index .Service.Labels "com.docker.stack.namespace"}}
export DOCKERSWARM_SERVICE_ID=${DOCKERSWARM_SERVICE_ID}
export DOCKERSWARM_SERVICE_NAME=${DOCKERSWARM_SERVICE_NAME}
export DOCKERSWARM_NODE_ID=${DOCKERSWARM_NODE_ID}
export DOCKERSWARM_NODE_HOSTNAME=${DOCKERSWARM_NODE_HOSTNAME}
export DOCKERSWARM_TASK_ID=${DOCKERSWARM_TASK_ID}
export DOCKERSWARM_TASK_NAME=${DOCKERSWARM_TASK_NAME}
export DOCKERSWARM_TASK_SLOT=${DOCKERSWARM_TASK_SLOT}
export DOCKERSWARM_STACK_NAMESPACE=${DOCKERSWARM_STACK_NAMESPACE}

echo "==> [Docker Swarm Entrypoint] Waiting for Docker to configure the network and DNS resolution... (${DOCKERSWARM_STARTUP_DELAY}s)"
sleep ${DOCKERSWARM_STARTUP_DELAY}

# 
# Implement your own logic here
# 

# Redirect the execution context to the original entrypoint, if needed
# Uncomment the following line to enable the original entrypoint
# exec /docker-entrypoint-shim.sh "${@}"
