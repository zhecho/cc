# Multi-stage build for minimal final image
FROM cgr.dev/chainguard/wolfi-base:latest AS builder

# Version arguments for static version management
ARG KUBECTL_VERSION=v1.34.1
ARG K9S_VERSION=v0.50.16
ARG GLAB_VERSION=v1.74.0
ARG HELM_VERSION=v3.19.0
ARG ARGO_VERSION=v3.7.3
ARG TERRAFORM_VERSION=1.13.4
ARG AWSCLI_VERSION=2.31.18
ARG BOTO3_VERSION=1.40.55
ARG OPENSSL_VERSION=3.5.1
ARG CRUSH_VERSION=0.12.0

# Install build dependencies
RUN apk update && apk add --no-cache \
    bash \
    curl \
    unzip \
    gnutar \
    ca-certificates

# Create tar symlink
RUN ln -sf $(which gnutar) /usr/bin/tar

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
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl" && \
    chmod +x kubectl && \
    mkdir -p /usr/local/bin && \
    mv kubectl /usr/local/bin/kubectl

# Install k9s (latest) with architecture detection
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        K9S_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        K9S_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -L "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_${K9S_ARCH}.tar.gz" -o k9s.tar.gz && \
    tar -xzf k9s.tar.gz && \
    chmod +x k9s && \
    mv k9s /usr/local/bin/ && \
    rm k9s.tar.gz

# Install GitLab CLI (glab) - official API client with architecture detection
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        GLAB_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        GLAB_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    GLAB_VERSION_NUM="${GLAB_VERSION#v}" && \
    curl -L "https://gitlab.com/api/v4/projects/gitlab-org%2Fcli/packages/generic/glab/${GLAB_VERSION_NUM}/glab_${GLAB_VERSION_NUM}_linux_${GLAB_ARCH}.tar.gz" -o glab.tar.gz && \
    tar -xzf glab.tar.gz && \
    chmod +x bin/glab && \
    mv bin/glab /usr/local/bin/ && \
    rm -rf glab.tar.gz bin/

# Argo CLI will be installed in final stage
# Crush CLI will be installed in final stage

# Helm will be installed in final stage

# Terraform will be installed in final stage

# Final stage - minimal runtime image
FROM cgr.dev/chainguard/wolfi-base:latest

# Version arguments for final stage
ARG TERRAFORM_VERSION=1.13.4
ARG TERRAFORM_VERSION_157=1.5.7
ARG ARGO_VERSION=v3.7.3
ARG AWSCLI_VERSION=2.31.18
ARG BOTO3_VERSION=1.40.55
ARG OPENSSL_VERSION=3.5.1
ARG CRUSH_VERSION=0.12.0

# Install available packages from Chainguard repositories
RUN apk update && apk add --no-cache \
    bash \
    ca-certificates \
    python3 \
    py3-pip \
    git \
    curl \
    jq \
    yq \
    binutils \
    unzip \
    nodejs-24 \
    npm \
    openssl \
    netcat-openbsd \
    cpio \
    rpm \
    && rm -rf /var/cache/apk/*

# Install container tools (podman and skopeo need special handling)
RUN apk add --no-cache podman skopeo || echo "Container tools may not be available in this Chainguard version"

# Install AWS CLI v2 using official installer and create virtual environment for boto3
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        AWS_ARCH="x86_64"; \
        SESSION_MANAGER_ARCH="64bit"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        AWS_ARCH="aarch64"; \
        SESSION_MANAGER_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    # Install AWS CLI v2 using official installer \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli && \
    rm -rf awscliv2.zip aws && \
    # Install AWS Session Manager Plugin \
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_${SESSION_MANAGER_ARCH}/session-manager-plugin.rpm" -o "session-manager-plugin.rpm" && \
    # Extract RPM manually since we don't have rpm command in Chainguard \
    (cd /tmp && \
     rpm2cpio /session-manager-plugin.rpm | cpio -idmv && \
     cp usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/ && \
     chmod +x /usr/local/bin/session-manager-plugin) || \
    # Fallback: try direct binary download if rpm method fails \
    (curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_${SESSION_MANAGER_ARCH}/session-manager-plugin" -o "/usr/local/bin/session-manager-plugin" && \
     chmod +x /usr/local/bin/session-manager-plugin) && \
    rm -f session-manager-plugin.rpm && \
    rm -rf /tmp/usr && \
    # Create virtual environment for boto3 \
    python3 -m venv /opt/aws-venv && \
    /opt/aws-venv/bin/pip install --upgrade pip && \
    /opt/aws-venv/bin/pip install boto3==${BOTO3_VERSION}

# Create a wrapper script for python3 that includes AWS venv in path
RUN printf '#!/bin/bash\nexport PYTHONPATH="/opt/aws-venv/lib/python3.12/site-packages:$PYTHONPATH"\nexec /usr/bin/python3 "$@"\n' > /usr/local/bin/python3-aws && \
    chmod +x /usr/local/bin/python3-aws

# Install Helm manually with architecture detection
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        HELM_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        HELM_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -L "https://get.helm.sh/helm-v3.19.0-linux-${HELM_ARCH}.tar.gz" -o helm.tar.gz && \
    tar -xzf helm.tar.gz && \
    chmod +x linux-${HELM_ARCH}/helm && \
    mv linux-${HELM_ARCH}/helm /usr/local/bin/ && \
    rm -rf helm.tar.gz linux-${HELM_ARCH}/

# Install Argo CLI with architecture detection
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        ARGO_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        ARGO_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -L "https://github.com/argoproj/argo-workflows/releases/download/${ARGO_VERSION}/argo-linux-${ARGO_ARCH}.gz" -o argo.gz && \
    gunzip argo.gz && \
    chmod +x argo && \
    mv argo /usr/local/bin/ && \
    rm -f argo.gz

# Install Crush CLI (Charmbracelet's AI coding agent) with architecture detection
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        CRUSH_ARCH="x86_64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        CRUSH_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -L "https://github.com/charmbracelet/crush/releases/download/v${CRUSH_VERSION}/crush_${CRUSH_VERSION}_Linux_${CRUSH_ARCH}.tar.gz" -o crush.tar.gz && \
    tar -xzf crush.tar.gz && \
    chmod +x crush_${CRUSH_VERSION}_Linux_${CRUSH_ARCH}/crush && \
    mv crush_${CRUSH_VERSION}_Linux_${CRUSH_ARCH}/crush /usr/local/bin/ && \
    rm -rf crush.tar.gz crush_${CRUSH_VERSION}_Linux_${CRUSH_ARCH}

# Install tfswitch (terraform version switcher) and terraform versions
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        TF_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        TF_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    # Install tfswitch from GitHub releases \
    TFSWITCH_VERSION="v1.7.0" && \
    curl -L "https://github.com/warrensbox/terraform-switcher/releases/download/${TFSWITCH_VERSION}/terraform-switcher_${TFSWITCH_VERSION}_linux_${TF_ARCH}.tar.gz" -o tfswitch.tar.gz && \
    tar -xzf tfswitch.tar.gz && \
    chmod +x tfswitch && \
    mv tfswitch /usr/local/bin/ && \
    rm tfswitch.tar.gz && \
    # Install terraform 1.13.4 (latest) \
    curl -L "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip" -o terraform_latest.zip && \
    unzip terraform_latest.zip && \
    chmod +x terraform && \
    mv terraform /usr/local/bin/terraform-1.13.4 && \
    rm terraform_latest.zip && \
    # Install terraform 1.5.7 \
    curl -L "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION_157}/terraform_${TERRAFORM_VERSION_157}_linux_${TF_ARCH}.zip" -o terraform_157.zip && \
    unzip terraform_157.zip && \
    chmod +x terraform && \
    mv terraform /usr/local/bin/terraform-1.5.7 && \
    rm terraform_157.zip && \
    # Set default terraform version (latest) \
    ln -sf /usr/local/bin/terraform-1.13.4 /usr/local/bin/terraform

# Copy other tools from builder stage
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=builder /usr/local/bin/k9s /usr/local/bin/k9s
COPY --from=builder /usr/local/bin/glab /usr/local/bin/glab

# Create non-root user with bash shell and specific UID/GID
RUN deluser --remove-home $(getent passwd 1000 | cut -d: -f1) 2>/dev/null || true && \
    adduser -D -s /bin/bash -u 1000 claude

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code@2.1.6

# Create a simple wrapper script for claude command
RUN printf '#!/bin/bash\nnode /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js "$@"\n' > /usr/local/bin/claude-wrapper && \
    chmod +x /usr/local/bin/claude-wrapper && \
    ln -sf /usr/local/bin/claude-wrapper /usr/local/bin/claude

# Install Gemini CLI globally (DISABLED - causes segfault with QEMU AMD64 emulation)
# RUN npm install -g @google/gemini-cli

# Create a simple wrapper script for gemini command (DISABLED)
# RUN printf '#!/bin/bash\nnode /usr/local/lib/node_modules/@google/gemini-cli/cli.js "$@"\n' > /usr/local/bin/gemini-wrapper && \
#     chmod +x /usr/local/bin/gemini-wrapper && \
#     ln -sf /usr/local/bin/gemini-wrapper /usr/local/bin/gemini

# Security hardening
RUN chmod 755 /usr/local/bin/kubectl /usr/local/bin/k9s /usr/local/bin/glab /usr/local/bin/crush /usr/local/bin/argo /usr/local/bin/helm /usr/local/bin/terraform /usr/local/bin/tfswitch

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