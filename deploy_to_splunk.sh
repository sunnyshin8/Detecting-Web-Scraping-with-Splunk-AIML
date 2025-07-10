#!/bin/bash

echo "=== Splunk Web Scraping Detection Deployment Script ==="

# Set SPLUNK_HOME via argument or default
SPLUNK_HOME="${1:-/c/Program\ Files/Splunk}"
APP_NAME="web_scraping_detection"
APP_PATH="$SPLUNK_HOME/etc/apps/$APP_NAME"

echo "Splunk Home: $SPLUNK_HOME"
echo "App Name: $APP_NAME"

# Validate SPLUNK_HOME
if [ ! -d "$SPLUNK_HOME" ]; then
  echo "❌ ERROR: Splunk directory not found at $SPLUNK_HOME"
  echo "Please specify the correct path like:"
  echo "  ./deploy_to_splunk.sh \"/c/Program Files/Splunk\""
  exit 1
fi

# Create required directories
echo "1. Creating app directory structure..."
mkdir -p "$APP_PATH/local" || { echo "Failed to create local/"; exit 1; }
mkdir -p "$APP_PATH/lookups" || { echo "Failed to create lookups/"; exit 1; }
mkdir -p "$APP_PATH/metadata" || { echo "Failed to create metadata/"; exit 1; }

# Copy config files
echo "2. Copying configuration files..."
cp -r splunk_config/* "$APP_PATH/local/" || { echo "❌ Failed to copy local config files."; exit 1; }
cp -r lookups/* "$APP_PATH/lookups/" || { echo "❌ Failed to copy lookups."; exit 1; }
cp -r metadata/* "$APP_PATH/metadata/" || { echo "❌ Failed to copy metadata."; exit 1; }

echo "✅ Deployment complete!"
