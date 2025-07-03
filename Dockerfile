FROM node:alpine

# Install bash
RUN apk update && apk add --no-cache bash

# Create non-root user with bash shell and specific UID/GID
RUN deluser --remove-home $(getent passwd 1000 | cut -d: -f1) 2>/dev/null || true && \
    adduser -D -s /bin/bash -u 1000 claude

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Create a simple wrapper script for claude command
RUN printf '#!/bin/bash\nnode /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js "$@"\n' > /usr/local/bin/claude-wrapper && \
    chmod +x /usr/local/bin/claude-wrapper && \
    ln -sf /usr/local/bin/claude-wrapper /usr/local/bin/claude

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