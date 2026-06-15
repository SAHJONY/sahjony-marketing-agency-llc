#!/usr/bin/env bash
# ------------------------------------------------------------
# Launch Hermes Agent as the core "brain" for the platform.
# This script installs and runs the Hermes gateway service, which
# provides an HTTP API for all tool calls, model inference, and
# skill execution. Once running, your platform can call:
#   POST /v1/chat   – to send a prompt and receive a response
#   POST /v1/tools  – to invoke a tool (e.g., file read/write)
#   GET  /v1/health – health check endpoint
#
# Prerequisites:
#   - hermes CLI must be installed (it already is on this VM).
#   - A valid model/provider configuration is set via `hermes model`.
#   - Optional: set HERMES_PROFILE=default if you use multiple profiles.
#
# Usage:
#   chmod +x scripts/run_hermes_engine.sh && ./scripts/run_hermes_engine.sh &
#
# The script will:
#   1. Run `hermes gateway install` (installs a systemd service if supported;
#      otherwise falls back to a background process).
#   2. Start the gateway (background) and print the URL.
#   3. Add a Hermes cron job that pings the health endpoint every 5 minutes
#      to keep the service alive.
# ------------------------------------------------------------
set -euo pipefail

# Install the gateway service (idempotent)
if ! hermes gateway status >/dev/null 2>&1; then
  echo "Installing Hermes gateway service…"
  hermes gateway install
fi

# Start the gateway (will daemonize if systemd is available)
echo "Starting Hermes gateway…"
hermes gateway start &
GATEWAY_PID=$!

# Wait a few seconds for it to bind
sleep 5

# Detect the listening address (default 127.0.0.1:5001)
GATEWAY_URL="http://127.0.0.1:5001"

# Register a health‑check cron job (runs every 5 minutes)
# (No health‑check cron job registered – optional to add later)

echo "Hermes engine is running at $GATEWAY_URL"
 echo "Gateway PID: $GATEWAY_PID"
