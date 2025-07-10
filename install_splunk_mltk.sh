#!/bin/bash

# Configuration
SPLUNK_HOME="/c/Program Files/Splunk"
APP_NAME="Splunk_ML_Toolkit"
MLTK_URL="https://download.splunk.com/products/mltk/releases/5.6.0/windows/splunk-machine-learning-toolkit_560.tgz"
MLTK_FILE="splunk-machine-learning-toolkit_560.tgz"

# Make sure SPLUNK_HOME exists
if [ ! -d "$SPLUNK_HOME" ]; then
  echo "❌ ERROR: SPLUNK_HOME not found at $SPLUNK_HOME"
  echo "Edit the script and set the correct SPLUNK_HOME path."
  exit 1
fi

# Navigate to apps folder
cd "$SPLUNK_HOME/etc/apps" || {
  echo "❌ ERROR: Cannot navigate to $SPLUNK_HOME/etc/apps"
  exit 1
}

echo "📥 Downloading Splunk MLTK..."
curl -L -o "$MLTK_FILE" "$MLTK_URL"

if [ ! -f "$MLTK_FILE" ]; then
  echo "❌ Download failed. File not found: $MLTK_FILE"
  exit 1
fi

echo "📦 Extracting $MLTK_FILE..."
tar -xvzf "$MLTK_FILE"

echo "🧹 Cleaning up..."
rm "$MLTK_FILE"

echo "✅ Splunk MLTK installed at: $SPLUNK_HOME/etc/apps/$APP_NAME"
