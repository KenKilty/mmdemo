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
EOL

# Get all rules that were skipped
echo "#### Skipped Rules" >> reports/analysis-report.md
echo "The following rules were skipped during analysis:" >> reports/analysis-report.md
echo "" >> reports/analysis-report.md

# Extract skipped rules
yq e '.[0].skipped[]' reports/output.yaml | while read -r rule; do
    echo "- $rule" >> reports/analysis-report.md
done

# Add summary section
echo "" >> reports/analysis-report.md
echo "## Summary" >> reports/analysis-report.md
echo "The analysis focused on Azure and Spring Boot migration rules. The following rules were skipped during analysis:" >> reports/analysis-report.md
SKIPPED_COUNT=$(yq e '.[0].skipped | length' reports/output.yaml)
echo "- Total skipped rules: $SKIPPED_COUNT" >> reports/analysis-report.md

echo -e "${GREEN}Report generated successfully! Check reports/analysis-report.md${NC}" 