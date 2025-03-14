#!/bin/bash

# Source bashrc to ensure environment variables are set
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi

# =============================================================================
# Platform Requirements
# =============================================================================
# This script has been tested on:
#   - macOS (Darwin) with Apple Silicon (ARM64)
#
# For other platforms, you will need to:
#   - macOS (Darwin) with Intel: Update KANTRA_URL to use the x86_64 binary
#   - Windows: Update KANTRA_URL to use the windows binary and adjust paths
#   - Linux: Update KANTRA_URL to use the linux binary and adjust paths
# =============================================================================

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Kantra version and download URL
KANTRA_VERSION="v0.6.1"
KANTRA_URL="https://github.com/konveyor/kantra/releases/download/${KANTRA_VERSION}/kantra.darwin.arm64.zip"

# Store the script's working directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Store the parent directory (where before-container version of the app is located)
PARENT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

# Create kantra directory if it doesn't exist
mkdir -p kantra

# Download and extract Kantra if not already installed
if [ ! -f "kantra/darwin-kantra" ] || [ ! -x "kantra/darwin-kantra" ]; then
    echo -e "${YELLOW}Downloading and extracting Kantra ${KANTRA_VERSION}...${NC}"
    cd kantra || exit 1
    curl -L -o kantra.darwin.arm64.zip "$KANTRA_URL" || { echo -e "${RED}Error: Failed to download Kantra${NC}" >&2; exit 1; }
    unzip -q kantra.darwin.arm64.zip || { echo -e "${RED}Error: Failed to extract Kantra${NC}" >&2; exit 1; }
    chmod +x darwin-kantra
    rm -f kantra.darwin.arm64.zip
    cd "$SCRIPT_DIR" || exit 1
    echo -e "${GREEN}Kantra setup complete!${NC}"
else
    echo -e "${YELLOW}Kantra is already installed.${NC}"
fi

# Clean up and recreate reports directory for a fresh start
echo -e "${YELLOW}Preparing reports directory...${NC}"
rm -rf reports
mkdir -p reports

# Clean up temporary files in the migration-konveyor directory
echo -e "${YELLOW}Cleaning up temporary files...${NC}"
rm -rf "$SCRIPT_DIR/temp"/* 2>/dev/null || true
rm -rf "$SCRIPT_DIR/cache"/* 2>/dev/null || true
rm -f "$SCRIPT_DIR/*.log" 2>/dev/null || true

# Clean up user Kantra logs and temporary files
echo -e "${YELLOW}Cleaning up Kantra logs and temporary files...${NC}"
rm -rf "$HOME/.kantra/logs"/* 2>/dev/null || true
rm -rf "$HOME/.kantra/cache"/* 2>/dev/null || true
rm -rf "$HOME/.kantra/temp"/* 2>/dev/null || true

# Run analysis with built-in cloud-readiness target and custom rules
echo -e "${YELLOW}Running analysis on before-container directory...${NC}"
if [ ! -d "$PARENT_DIR/before-container" ]; then
    echo -e "${RED}Error: before-container directory not found at $PARENT_DIR/before-container${NC}" >&2
    exit 1
fi

cd kantra && ./darwin-kantra analyze \
  --input "$PARENT_DIR/before-container" \
  --output "$SCRIPT_DIR/reports" \
  --target cloud-readiness \
  --rules "$SCRIPT_DIR/rulesets" \
  --overwrite \
  --skip-static-report

echo -e "${GREEN}Analysis complete! Results are available in the reports directory:${NC}"
echo -e "  - ${YELLOW}output.yaml${NC}: Detailed analysis results in YAML format"
echo -e "  - ${YELLOW}output.json${NC}: Analysis results in JSON format"
echo -e "  - ${YELLOW}dependencies.yaml${NC}: Project dependencies analysis"
echo -e "  - ${YELLOW}analysis.log${NC}: Detailed analysis log file"
