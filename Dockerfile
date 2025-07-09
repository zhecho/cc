# Multi-stage build for minimal final image
FROM alpine:3.20 AS builder

# Install build dependencies
RUN apk update && apk add --no-cache \
    bash \
    curl \
    unzip \
    tar \
    ca-certificates

# Install AWS CLI v2 (latest)
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /aws-cli-bin --install-dir /aws-cli && \
    rm -rf awscliv2.zip aws/

# Install kubectl (latest stable)
RUN KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install k9s (latest)
RUN K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
    curl -L "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" -o k9s.tar.gz && \
    tar -xzf k9s.tar.gz && \
    chmod +x k9s && \
    mv k9s /usr/local/bin/ && \
    rm k9s.tar.gz

# Install GitLab CLI (glab) - official API client
RUN GLAB_VERSION=$(curl -s https://api.github.com/repos/profclems/glab/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
    curl -L "https://github.com/profclems/glab/releases/download/${GLAB_VERSION}/glab_${GLAB_VERSION#v}_Linux_x86_64.tar.gz" -o glab.tar.gz && \
    tar -xzf glab.tar.gz && \
    chmod +x bin/glab && \
    mv bin/glab /usr/local/bin/ && \
    rm -rf glab.tar.gz bin/

# Final stage - minimal runtime image
FROM node:20-alpine3.20

# Install only essential runtime dependencies
RUN apk update && apk add --no-cache \
    bash \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Copy tools from builder stage
COPY --from=builder /aws-cli-bin/aws /usr/local/bin/aws
COPY --from=builder /aws-cli /usr/local/aws-cli
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
RUN chmod 755 /usr/local/bin/aws /usr/local/bin/kubectl /usr/local/bin/k9s /usr/local/bin/glab && \
    find /usr/local/aws-cli -type f -exec chmod 644 {} \; && \
    find /usr/local/aws-cli -type d -exec chmod 755 {} \;

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