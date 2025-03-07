#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Function to check prerequisites
check_prerequisites() {
    command -v podman >/dev/null 2>&1 || { echo "Error: podman is not installed"; exit 1; }
    command -v curl >/dev/null 2>&1 || { echo "Error: curl is not installed"; exit 1; }
}

# Function to wait for the application to be ready
wait_for_app() {
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s -L http://localhost:18080/todo >/dev/null; then
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 5
    done
    return 1
}

# Function to clean up containers
cleanup_containers() {
    cd "$SCRIPT_DIR"
    podman-compose -f docker-compose.yml down
    podman rm -f $(podman ps -aq) 2>/dev/null || true
}

# Function to start containers
start_containers() {
    cd "$SCRIPT_DIR"
    cleanup_containers
    podman-compose -f docker-compose.yml up -d --build
    wait_for_app || { echo "Application failed to start"; exit 1; }
}

# Function to stop containers
stop_containers() {
    cleanup_containers
}

# Function to restart containers
restart_containers() {
    cleanup_containers
    start_containers
}

# Main script
check_prerequisites

case "$1" in
    "start")
        start_containers
        ;;
    "stop")
        stop_containers
        ;;
    "restart")
        restart_containers
        ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
        ;;
esac 