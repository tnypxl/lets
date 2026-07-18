#!/usr/bin/env bash
# Loads app configuration from app/config.json and exports the values.
set -euo pipefail

CONFIG_FILE="$(dirname "${BASH_SOURCE[0]}")/config.json"

APP_NAME="$(python3 -c "import json;print(json.load(open('$CONFIG_FILE'))['name'])")"
APP_PORT="$(python3 -c "import json;print(json.load(open('$CONFIG_FILE'))['port'])")"

export APP_NAME APP_PORT
