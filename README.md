# Claude Code Container

A secure, minimal containerized version of Claude Code CLI with the latest cloud and DevOps tools for portable usage across different systems.

## Features

- **Latest Cloud & DevOps Tools:**
  - AWS CLI v1 (latest) - Amazon Web Services command-line interface
  - kubectl (latest stable) - Kubernetes command-line tool
  - k9s (latest) - Kubernetes cluster management UI
  - glab (latest) - Official GitLab CLI API client
  - git (latest) - Distributed version control system
  - Claude Code CLI - AI-powered development assistant

- **Security & Optimization:**
  - Multi-stage build for minimal image size (927 MB)
  - Alpine Linux 3.20 base for security and size
  - Non-root user (UID 1000) for security
  - Proper file permissions and security hardening
  - Minimal runtime dependencies

## Usage

### Prerequisites
- Podman or Docker installed
- Claude Code configuration directory on host

### Quick Start

1. **Create config directory** (first time only):
```bash
mkdir -p ~/.claude
```

2. **Run container with interactive bash shell**:
```bash
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  claude-code-secure:latest
```

3. **Inside container, access all tools**:
```bash
# Claude Code CLI
claude --version
claude

# AWS CLI
aws --version
aws s3 ls

# Kubernetes tools
kubectl version --client
k9s version

# GitLab CLI
glab version
glab auth login

# Git client
git --version
git status
git clone <repository>
```

### Usage Examples

```bash
# Interactive bash session (recommended)
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  claude-code-secure:latest

# Run specific Claude command directly
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  claude-code-secure:latest -c "claude --version"

# Use AWS CLI directly
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  -v ~/.aws:/home/claude/.aws:Z \
  claude-code-secure:latest -c "aws s3 ls"

# Use kubectl with kubeconfig
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  -v ~/.kube:/home/claude/.kube:Z \
  claude-code-secure:latest -c "kubectl get pods"

# Use GitLab CLI
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  claude-code-secure:latest -c "glab issue list"
```

## Volume Mounts

- `/workspace` - Your project directory
- `/home/claude/.claude` - Claude Code config and credentials
- `/home/claude/.aws` - AWS CLI credentials (optional)
- `/home/claude/.kube` - Kubernetes config (optional)
- `/home/claude/.config/glab-cli` - GitLab CLI config (optional)

## Podman Flags Explained

- `--privileged` - Required for some Claude Code operations
- `--userns=keep-id` - Preserves user/group IDs for file permissions
- `:Z` - SELinux context for shared volumes (Linux systems)
- `-v ./.:/workspace` - Mounts current directory to container workspace

## Building Locally

```bash
# Build secure image with latest tools
podman build -t claude-code-secure .

# Run locally built image
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  claude-code-secure
```

## Tools Included

| Tool | Version | Purpose |
|------|---------|---------|
| Claude Code CLI | Latest | AI-powered development assistant |
| AWS CLI v1 | Latest | Amazon Web Services command-line interface |
| kubectl | Latest stable | Kubernetes command-line tool |
| k9s | Latest | Kubernetes cluster management UI |
| glab | Latest | Official GitLab CLI API client |
| git | Latest | Distributed version control system |

## Security Features

- **Multi-stage build** reduces final image size and attack surface
- **Non-root user** (UID 1000) for secure container execution
- **Minimal base image** (Alpine Linux 3.20) for security
- **Proper file permissions** (755 for binaries, 644 for files)
- **Clean package management** with cache removal
- **Security hardening** applied to all installed tools
