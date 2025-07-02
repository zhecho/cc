FROM node:alpine

# Create non-root user
RUN adduser -D -s /bin/sh claude

# Install Claude Code CLI globally
RUN npm install -g @anthropic-ai/claude-code

# Create directories with proper permissions
RUN mkdir -p /home/claude/.claude /workspace && \
    chown -R claude:claude /home/claude /workspace

# Switch to non-root user
USER claude

# Set working directory
WORKDIR /workspace

# Set entrypoint to Claude Code CLI
ENTRYPOINT ["node", "/usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js"]