#!/bin/bash
# Robust Xvfb startup script for stealth browser
# Starts Xvfb explicitly and waits for it to be ready before running node

set -e

DISPLAY_NUM=99
export DISPLAY=:${DISPLAY_NUM}

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    if [ -n "$NODE_PID" ] && kill -0 "$NODE_PID" 2>/dev/null; then
        echo "Stopping node process (PID: $NODE_PID)..."
        kill -TERM "$NODE_PID" 2>/dev/null || true
        wait "$NODE_PID" 2>/dev/null || true
    fi
    if [ -n "$XVFB_PID" ] && kill -0 "$XVFB_PID" 2>/dev/null; then
        echo "Stopping Xvfb (PID: $XVFB_PID)..."
        kill -TERM "$XVFB_PID" 2>/dev/null || true
        wait "$XVFB_PID" 2>/dev/null || true
    fi
    # Clean up lock file if it exists
    rm -f "/tmp/.X${DISPLAY_NUM}-lock" 2>/dev/null || true
    echo "Cleanup complete"
}

# Set up signal handlers
trap cleanup EXIT
trap 'echo "Received SIGTERM"; exit 0' SIGTERM
trap 'echo "Received SIGINT"; exit 0' SIGINT

# Clean up any stale lock files from previous runs
rm -f "/tmp/.X${DISPLAY_NUM}-lock" 2>/dev/null || true

echo "Starting Xvfb on display :${DISPLAY_NUM}..."
Xvfb :${DISPLAY_NUM} -screen 0 1920x1080x24 -nolisten tcp &
XVFB_PID=$!

# Wait for Xvfb to create the socket (max 10 seconds)
echo "Waiting for Xvfb to be ready..."
for i in $(seq 1 100); do
    if [ -e "/tmp/.X${DISPLAY_NUM}-lock" ]; then
        echo "Xvfb lock file exists (took ~$((i * 100))ms)"
        break
    fi
    sleep 0.1
done

if [ ! -e "/tmp/.X${DISPLAY_NUM}-lock" ]; then
    echo "ERROR: Xvfb failed to start within 10 seconds"
    exit 1
fi

# Verify Xvfb is still running
if ! kill -0 "$XVFB_PID" 2>/dev/null; then
    echo "ERROR: Xvfb process died unexpectedly"
    exit 1
fi

# Small delay to ensure X server is fully initialized
sleep 0.5

# Verify DISPLAY is usable (optional but helps catch issues early)
if command -v xdpyinfo &>/dev/null; then
    if xdpyinfo -display :${DISPLAY_NUM} &>/dev/null; then
        echo "X server verified with xdpyinfo"
    else
        echo "WARNING: xdpyinfo check failed (may still work)"
    fi
fi

echo "Starting node server.js with DISPLAY=${DISPLAY}..."
echo "  Xvfb PID: $XVFB_PID"

# Start node in the background so we can wait on it
node server.js &
NODE_PID=$!
echo "  Node PID: $NODE_PID"

# Wait for node process - this allows signal handlers to work properly
wait "$NODE_PID"
NODE_EXIT_CODE=$?

echo "Node process exited with code: $NODE_EXIT_CODE"
exit $NODE_EXIT_CODE
