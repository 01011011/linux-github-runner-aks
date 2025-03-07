FROM ubuntu:22.04

# Set environment variables
ENV RUNNER_VERSION=2.322.0
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages and Azure CLI dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    git \
    iputils-ping \
    net-tools \
    software-properties-common \
    sudo \
    apt-transport-https \
    lsb-release \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Docker CLI
RUN apt-get update && apt-get install -y docker.io

# Create runner user and directory
RUN useradd -m runner && \
    mkdir -p /home/runner/actions-runner && \
    chown -R runner:runner /home/runner

# Allow runner to run sudo commands without a password
RUN echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Add runner user to docker group so they can run docker commands
RUN sudo usermod -aG docker runner

# Switch to runner user
USER runner
WORKDIR /home/runner/actions-runner

# Download and extract GitHub runner
RUN curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz && \
    rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz

# Copy startup script and set it executable
COPY --chown=runner:runner start.sh .
RUN chmod +x start.sh

ENTRYPOINT ["./start.sh"]