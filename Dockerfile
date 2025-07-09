# Multi-stage build for minimal final image
FROM alpine:3.20 AS builder

# Install build dependencies
RUN apk update && apk add --no-cache \
    bash \
    curl \
    unzip \
    tar \
    ca-certificates

# AWS CLI will be installed via pip in final stage

# Install kubectl (latest stable) with architecture detection
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        KUBECTL_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        KUBECTL_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install k9s (latest) with architecture detection
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        K9S_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        K9S_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
    curl -L "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${K9S_ARCH}.tar.gz" -o k9s.tar.gz && \
    tar -xzf k9s.tar.gz && \
    chmod +x k9s && \
    mv k9s /usr/local/bin/ && \
    rm k9s.tar.gz

# Install GitLab CLI (glab) - official API client with architecture detection
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        GLAB_ARCH="x86_64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        GLAB_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    GLAB_VERSION=$(curl -s https://api.github.com/repos/profclems/glab/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
    curl -L "https://github.com/profclems/glab/releases/download/${GLAB_VERSION}/glab_${GLAB_VERSION#v}_Linux_${GLAB_ARCH}.tar.gz" -o glab.tar.gz && \
    tar -xzf glab.tar.gz && \
    chmod +x bin/glab && \
    mv bin/glab /usr/local/bin/ && \
    rm -rf glab.tar.gz bin/

# Final stage - minimal runtime image
FROM node:20-alpine3.20

# Install only essential runtime dependencies with glibc support
RUN apk update && apk add --no-cache \
    bash \
    ca-certificates \
    libc6-compat \
    python3 \
    py3-pip \
    git \
    && rm -rf /var/cache/apk/*

# Install AWS CLI via pip (more Alpine-compatible)
RUN pip3 install awscli --break-system-packages

# Copy other tools from builder stage
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/k9s /usr/local/bin/k9s
COPY --from=builder /usr/local/bin/glab /usr/local/bin/glab

# Create non-root user with bash shell and specific UID/GID
RUN deluser --remove-home $(getent passwd 1000 | cut -d: -f1) 2>/dev/null || true && \
    adduser -D -s /bin/bash -u 1000 claude

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Create a simple wrapper script for claude command
RUN printf '#!/bin/bash\nnode /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js "$@"\n' > /usr/local/bin/claude-wrapper && \
    chmod +x /usr/local/bin/claude-wrapper && \
    ln -sf /usr/local/bin/claude-wrapper /usr/local/bin/claude

# Security hardening
RUN chmod 755 /usr/local/bin/kubectl /usr/local/bin/k9s /usr/local/bin/glab

# Create directories with proper permissions
RUN mkdir -p /home/claude/.claude /workspace && \
    chown -R claude:claude /home/claude /workspace

# Switch to non-root user
USER claude

# Set working directory
WORKDIR /workspace

# Set default shell environment variable
ENV SHELL=/bin/bash

# Use bash as entrypoint
ENTRYPOINT ["/bin/bash"]