# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a containerized version of Claude Code CLI bundled with essential cloud and DevOps tools. It provides a secure, portable development environment using Chainguard Images (Wolfi Linux) as the base for maximum security and glibc compatibility.

## Container Build Commands

### Build the container image locally
```bash
podman build -t claude-code-secure .
```

### Build using Docker Compose
```bash
docker-compose build
```

### Build multi-platform image (matches GitHub Actions)
```bash
podman build --platform linux/amd64,linux/arm64 -t claude-code-secure .
```

## Running the Container

### Interactive development session (recommended)
```bash
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  claude-code-secure:latest
```

### Using Docker Compose
```bash
docker-compose run --rm claude-code
```

### Run specific commands
```bash
# Run Claude Code directly
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  claude-code-secure:latest -c "claude --version"

# Run with AWS CLI
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  -v ~/.aws:/home/claude/.aws:Z \
  claude-code-secure:latest -c "aws s3 ls"
```

## Architecture

### Multi-stage Build
The Dockerfile uses a multi-stage build pattern:
- **Builder stage**: Downloads and prepares binaries for kubectl, k9s, and glab
- **Final stage**: Creates minimal runtime image with all tools and proper security hardening

### Security Features
- Non-root user execution (UID 1000)
- Chainguard Images base for zero-CVE target
- Proper file permissions (755 for binaries, 644 for files)
- Multi-stage build reduces attack surface
- Security hardening applied to all tools

### Tool Versions
Version arguments are centralized at the top of the Dockerfile:
- `KUBECTL_VERSION`: Kubernetes CLI version
- `K9S_VERSION`: Kubernetes cluster management UI version
- `GLAB_VERSION`: GitLab CLI version
- `TERRAFORM_VERSION`: Default Terraform version (1.12.2)
- `TERRAFORM_VERSION_157`: Alternative Terraform version (1.5.7)
- `AWSCLI_VERSION`: AWS CLI v2 version
- `BOTO3_VERSION`: AWS SDK for Python version

## Installed Tools

The container includes these pre-installed tools:
- **Claude Code CLI**: AI-powered development assistant
- **AWS CLI v2**: Amazon Web Services command-line interface
- **kubectl**: Kubernetes command-line tool
- **k9s**: Kubernetes cluster management UI
- **glab**: Official GitLab CLI API client
- **git**: Distributed version control system
- **terraform**: Infrastructure as Code tool (multiple versions available)
- **tfswitch**: Terraform version switcher
- **boto3**: AWS SDK for Python (in virtual environment)
- **Node.js & npm**: JavaScript runtime and package manager
- **jq & yq**: JSON and YAML processors
- **podman & skopeo**: Container tools

## Terraform Version Management

The container includes multiple Terraform versions:
- `terraform` (default): Points to Terraform 1.12.2
- `terraform-1.5.7`: Direct access to Terraform 1.5.7
- `tfswitch`: Switch between versions interactively

### Terraform Usage
```bash
# Use default version
terraform version

# Use specific version directly
terraform-1.5.7 version

# Switch versions using tfswitch
tfswitch 1.5.7
```

## Volume Mounts

Essential directories to mount:
- `/workspace`: Your project directory (maps to current directory)
- `/home/claude/.claude`: Claude Code configuration and credentials
- `/home/claude/.aws`: AWS CLI credentials (optional)
- `/home/claude/.kube`: Kubernetes configuration (optional)

## GitHub Actions Integration

The repository includes automated CI/CD via `.github/workflows/build.yml`:
- Builds multi-platform images (linux/amd64, linux/arm64)
- Pushes to GitHub Container Registry (ghcr.io)
- Triggers on pushes to main branch and pull requests
- Uses semantic versioning with branch, PR, and SHA tags

## Development Workflow

1. Make changes to the Dockerfile or supporting files
2. Build locally to test: `podman build -t claude-code-secure .`
3. Run container to verify functionality
4. Push changes to trigger GitHub Actions build
5. Published images available at `ghcr.io/zhecho/claude-code`

## Environment Variables

The container runs with:
- `SHELL=/bin/bash`: Default shell
- `PYTHONPATH` includes AWS virtual environment for boto3 access
- Working directory set to `/workspace`