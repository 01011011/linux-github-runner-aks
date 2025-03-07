#!/bin/bash
set -e

# Add a delay to ensure the environment is fully initialized
sleep 10

# Start Docker daemon in the background using sudo, writing logs to /tmp/dockerd.log
echo "Starting Docker daemon..."
sudo dockerd --host=unix:///var/run/docker.sock --host=tcp://0.0.0.0:2375 --storage-driver=vfs > /tmp/dockerd.log 2>&1 &

# Wait for the Docker daemon to be ready (retry loop)
echo "Waiting for Docker daemon to start..."
tries=0
while ! docker info > /dev/null 2>&1; do
  sleep 2
  tries=$((tries + 1))
  if [ $tries -ge 15 ]; then
    echo "Docker daemon did not start within expected time"
    exit 1
  fi
done
echo "Docker daemon started."

# Function to deregister the runner on termination
function cleanup() {
    echo "Received SIGTERM, deregistering runner..."
    if [ -f ".runner" ]; then
        ./config.sh remove --unattended --token "${ACCESS_TOKEN}"
    fi
    exit 0
}

trap cleanup SIGTERM

# Configure runner if not already configured
if [ ! -f ".runner" ]; then
    echo "Configuring runner..."
    ./config.sh --unattended \
      --url "https://github.com/${ORGANIZATION}/${REPOSITORY}" \
      --token "${ACCESS_TOKEN}" \
      --name "${RUNNER_NAME:-$(hostname)}" \
      --labels "${RUNNER_LABELS:-k8s,latest}"
fi

echo "Starting runner..."
exec ./run.sh