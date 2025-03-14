#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

# Function to check if script exists and make it executable
check_script() {
    local dir=$1
    local script=$2
    [ ! -f "$dir/$script" ] && { print_error "Error: $dir/$script not found"; exit 1; }
    [ ! -x "$dir/$script" ] && chmod +x "$dir/$script"
}

# Function to display usage
show_usage() {
    print_status "Todo Application Runner"
    echo
    echo -e "Usage: $0 {legacy|container|analyze|deploy} {action}"
    echo
    echo -e "Versions:"
    echo -e "  ${GREEN}legacy${NC}    - Run the legacy version of the application"
    echo -e "  ${GREEN}container${NC} - Run the containerized version of the application"
    echo -e "  ${GREEN}analyze${NC}   - Run Konveyor analysis"
    echo -e "  ${GREEN}deploy${NC}    - Deploy to Kubernetes"
    echo
    echo -e "Actions for legacy/container:"
    echo -e "  ${GREEN}start${NC}   - Start the application"
    echo -e "  ${GREEN}stop${NC}    - Stop the application"
    echo -e "  ${GREEN}restart${NC} - Restart the application"
    echo
    echo -e "Actions for analyze:"
    echo -e "  ${GREEN}run${NC}     - Run full analysis"
    echo -e "  ${GREEN}report${NC}  - Generate analysis report"
    echo
    echo -e "Actions for deploy:"
    echo -e "  ${GREEN}local${NC}   - Deploy to local Kubernetes"
    echo -e "  ${GREEN}aks${NC}     - Deploy to AKS"
    echo -e "  ${GREEN}clean${NC}   - Clean up deployment"
    echo
    exit 1
}

# Validate arguments
[ $# -ne 2 ] && show_usage
[[ ! "$1" =~ ^(legacy|container|analyze|deploy)$ ]] && { print_error "Error: Invalid version. Must be 'legacy', 'container', 'analyze', or 'deploy'"; show_usage; }

VERSION=$1
ACTION=$2

# Validate actions based on version
case "$VERSION" in
    legacy|container)
        [[ ! "$ACTION" =~ ^(start|stop|restart)$ ]] && { print_error "Error: Invalid action for $VERSION. Must be 'start', 'stop', or 'restart'"; show_usage; }
        ;;
    analyze)
        [[ ! "$ACTION" =~ ^(run|report)$ ]] && { print_error "Error: Invalid action for analyze. Must be 'run' or 'report'"; show_usage; }
        ;;
    deploy)
        [[ ! "$ACTION" =~ ^(local|aks|clean)$ ]] && { print_error "Error: Invalid action for deploy. Must be 'local', 'aks', or 'clean'"; show_usage; }
        ;;
esac

# Function to check if podman is running
check_podman() {
    if ! command -v podman &> /dev/null; then
        print_error "Error: Podman is not installed. Please install podman first."
        exit 1
    fi
    
    # Check if podman machine is running
    if ! podman machine list 2>/dev/null | grep -q "Currently running"; then
        print_warning "Podman machine is not running. Starting..."
        podman machine start
    fi
    
    print_success "Podman is ready"
}

# Function to check if curl is installed
check_curl() {
    if ! command -v curl &> /dev/null; then
        print_error "Error: curl is not installed. Please install curl first."
        exit 1
    fi
    print_success "curl is installed"
}

# Function to wait for the application to be ready
wait_for_app() {
    local max_attempts=12
    local attempt=1
    local wait_time=5
    
    print_status "Waiting for application to be ready..."
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts..."
        if curl -s http://localhost:18080/todo/health | grep -q '"status":"UP"'; then
            print_success "Application is healthy!"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep $wait_time
    done
    
    print_error "Application failed to become healthy after $max_attempts attempts"
    return 1
}

# Function to stop containers
stop_containers() {
    print_status "Stopping containers..."
    # Check if containers are running
    if podman ps | grep -q "after-container"; then
        podman-compose down
        print_success "Containers stopped successfully"
    else
        print_warning "No running containers found"
    fi
}

# Function to start containers
start_containers() {
    print_status "Starting containers..."
    podman-compose up -d --build
    
    # Wait for the application to be ready
    wait_for_app
}

# Function to restart containers
restart_containers() {
    stop_containers
    start_containers
}

# Main script
# Only check for curl as it's needed for all versions
check_curl

# Execute the appropriate script
if [ "$VERSION" = "analyze" ]; then
    check_script "migration-konveyor" "analyze.sh"
    print_status "Konveyor Analysis"
    
    case "$ACTION" in
        run)
            print_status "Running Konveyor analysis..."
            cd migration-konveyor && ./analyze.sh --mode full
            ;;
        report)
            print_status "Generating analysis report..."
            cd migration-konveyor && ./analyze.sh --report
            ;;
    esac
elif [ "$VERSION" = "deploy" ]; then
    # Container deployments need podman
    check_podman
    check_script "migration-draft" "deploytok8s.sh"
    print_status "Kubernetes Deployment"
    
    case "$ACTION" in
        local)
            print_status "Deploying to local Kubernetes..."
            cd migration-draft && ./deploytok8s.sh local
            ;;
        aks)
            print_status "Deploying to AKS..."
            cd migration-draft && ./deploytok8s.sh aks
            ;;
        clean)
            print_status "Cleaning up deployment..."
            cd migration-draft && ./deploytok8s.sh clean
            ;;
    esac
elif [ "$VERSION" = "legacy" ]; then
    check_script "before-container" "run-legacy.sh"
    print_status "Legacy Todo Application"
    
    # Legacy version doesn't need podman
    # Map the action to run-legacy.sh parameters
    case "$ACTION" in
        start)
            print_status "Starting legacy application..."
            print_success "URL: http://localhost:8080/legacy-todo\n"
            cd before-container && ./run-legacy.sh run > >(grep -v "Usage:")
            ;;
        stop)
            print_status "Stopping legacy application..."
            # Kill any running Java processes on port 8080
            if lsof -ti:8080 &>/dev/null; then
                lsof -ti:8080 | xargs kill -9 2>/dev/null
                print_success "Legacy application stopped"
            else
                print_warning "No legacy application running"
            fi
            ;;
        restart)
            print_status "Restarting legacy application..."
            # Kill any running processes and start again
            if lsof -ti:8080 &>/dev/null; then
                lsof -ti:8080 | xargs kill -9 2>/dev/null
                print_success "Previous instance stopped"
            fi
            print_success "URL: http://localhost:8080/legacy-todo\n"
            cd before-container && ./run-legacy.sh run > >(grep -v "Usage:")
            ;;
    esac
else
    # Container version needs podman
    check_podman
    check_script "after-container" "run-container.sh"
    print_status "Containerized Todo Application"
    
    case "$ACTION" in
        start)
            print_status "Starting containerized application..."
            cd after-container && ./run-container.sh start
            print_success "\nContainer URLs:"
            print_success "  App:    http://localhost:18080/todo"
            print_success "  Health: http://localhost:18080/todo/health"
            ;;
        stop)
            print_status "Stopping containerized application..."
            cd after-container && ./run-container.sh stop
            ;;
        restart)
            print_status "Restarting containerized application..."
            cd after-container && ./run-container.sh restart
            print_success "\nContainer URLs:"
            print_success "  App:    http://localhost:18080/todo"
            print_success "  Health: http://localhost:18080/todo/health"
            ;;
    esac
fi