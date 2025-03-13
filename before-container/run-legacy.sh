#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to check and cleanup port
cleanup_port() {
    local port=$1
    if lsof -i ":$port" >/dev/null 2>&1; then
        echo -e "${YELLOW}Cleaning up port $port...${NC}"
        lsof -ti:$port | xargs kill -9 2>/dev/null || true
        sleep 1
        if lsof -i ":$port" >/dev/null 2>&1; then
            echo -e "${RED}Port $port is still in use. Run: lsof -i :$port${NC}"
            exit 1
        fi
    fi
}

# Function to display usage
usage() {
    echo "Usage: $0 [run|debug|help]"
    echo "  run   - Start application"
    echo "  debug - Start with debugger (port 18787)"
}

# Cleanup before starting
cleanup_port 8080
[ "$1" = "debug" ] && cleanup_port 18787
rm -rf data/cache/eh* 2>/dev/null || true

case "$1" in
    debug)
        export MAVEN_OPTS="-agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=18787"
        mvn clean package cargo:run
        ;;
    run)
        mvn clean package cargo:run
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo -e "${RED}Invalid command: $1${NC}"
        usage
        exit 1
        ;;
esac

echo ""
echo -e "${BOLD}${BLUE}=======================================================${NC}"
echo -e "${BOLD}${GREEN}LOCAL TESTING INFORMATION${NC}"
echo -e "${BOLD}${BLUE}=======================================================${NC}"
echo -e "  Application URL: ${GREEN}http://localhost:8080/legacy-todo${NC}"
echo -e "  API Endpoint:    ${GREEN}http://localhost:8080/legacy-todo/api/todos${NC}"
echo -e "  Health Check:    ${GREEN}http://localhost:8080/legacy-todo/health${NC}"
if [ "$1" = "debug" ]; then
    echo -e "  Debug port:     ${GREEN}18787${NC}"
fi
echo -e "${BOLD}${BLUE}=======================================================${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the application${NC}"