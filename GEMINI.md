# GEMINI.md

This file provides guidance to Gemini when working with code in this repository.

## Project Overview

This is a containerized version of the Gemini CLI and Claude Code CLI bundled with essential cloud and DevOps tools. It provides a secure, portable development environment using Chainguard Images (Wolfi Linux) as the base for maximum security and glibc compatibility.

## Container Build Commands

### Build the container image locally
```bash
podman build -t claude-gemini-secure .
```

### Build using Docker Compose
```bash
docker-compose build
```

### Build multi-platform image (matches GitHub Actions)
```bash
podman build --platform linux/amd64,linux/arm64 -t claude-gemini-secure .
```

## Running the Container

### Interactive development session (recommended)
```bash
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  -v ~/.gemini:/home/claude/.gemini:Z \
  claude-gemini-secure:latest
```

### Run specific commands
```bash
# Run Gemini CLI
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.gemini:/home/claude/.gemini:Z \
  claude-gemini-secure:latest -c "gemini --version"

# Run Claude Code CLI
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  claude-gemini-secure:latest -c "claude --version"
```

## Installed Tools

The container includes these pre-installed tools:
- **Gemini CLI**: AI-powered development assistant
- **Claude Code CLI**: AI-powered development assistant
- **AWS CLI v2**, **kubectl**, **k9s**, **glab**, **git**, **terraform**, **tfswitch**, **boto3**, **Node.js & npm**, **jq & yq**, **podman & skopeo**

## Volume Mounts

Essential directories to mount:
- `/workspace`: Your project directory
- `/home/claude/.gemini`: Gemini configuration and credentials
- `/home/claude/.claude`: Claude Code configuration and credentials
- `/home/claude/.aws`: AWS CLI credentials (optional)
- `/home/claude/.kube`: Kubernetes configuration (optional)

```