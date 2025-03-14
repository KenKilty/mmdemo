#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Store the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo -e "${RED}Error: yq is required but not installed. Please install it first:${NC}"
    echo "  brew install yq"
    exit 1
fi

# Check if output.yaml exists
if [ ! -f "reports/output.yaml" ]; then
    echo -e "${RED}Error: reports/output.yaml not found. Run analyze.sh first.${NC}"
    exit 1
fi

# Create markdown report
echo -e "${YELLOW}Generating markdown report...${NC}"
cat > reports/analysis-report.md << 'EOL'
# Migration Analysis Report

## Overview
This report summarizes the findings from the Konveyor Kantra analysis of the application codebase.

## Analysis Results

### Azure/Spring Boot Migration
#### Violations Found
The following violations were identified during analysis:
EOL

# Process each violation
yq e '.. | select(has("violations")) | .violations | to_entries | .[] | "### " + .key + "\n- Description: " + .value.description + "\n- Category: " + .value.category + "\n- Labels: " + (.value.labels | join(", "))' reports/output.yaml >> reports/analysis-report.md

# Add incidents section
echo "" >> reports/analysis-report.md
echo "#### Incidents" >> reports/analysis-report.md
echo "The following specific issues were found:" >> reports/analysis-report.md
echo "" >> reports/analysis-report.md

# Process incidents - with clean paths
yq e '.. | select(has("violations")) | .violations | to_entries | .[] | 
  "##### " + .key + "\n" + 
  (.value.incidents[] | 
    "- **Location**: `" + (.uri | sub("^file:///Users/[^/]*/Documents/source/mmdemo/", "")) + "`\n" +
    "  **Details**: " + (.message // "No additional details provided.") + "\n"
  )' reports/output.yaml >> reports/analysis-report.md

# Add summary section
echo "" >> reports/analysis-report.md
echo "## Summary" >> reports/analysis-report.md
VIOLATION_COUNT=$(yq e '.. | select(has("violations")) | .violations | length' reports/output.yaml)
INCIDENT_COUNT=$(yq e '[.. | select(has("violations")) | .violations | .[].incidents | select(.)] | flatten | length' reports/output.yaml)
echo "The analysis identified $VIOLATION_COUNT violations with $INCIDENT_COUNT specific incidents in the codebase that need to be addressed for cloud readiness." >> reports/analysis-report.md

echo -e "${GREEN}Report generated successfully! Check reports/analysis-report.md${NC}" 