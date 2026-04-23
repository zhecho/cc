# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a containerized version of Claude Code CLI bundled with essential cloud
and DevOps tools. It provides a secure, portable development environment using
Chainguard Images (Wolfi Linux) as the base for maximum security and glibc
compatibility.

## Container Build Commands

### Build the container image locally
```bash
podman build -t claude-code-secure .
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
- `KUBECTL_VERSION`: Kubernetes CLI version (v1.35.4)
- `K9S_VERSION`: Kubernetes cluster management UI version (v0.50.18)
- `GLAB_VERSION`: GitLab CLI version (v1.92.1)
- `HELM_VERSION`: Kubernetes package manager (v4.1.4)
- `ARGO_VERSION`: Argo Workflows CLI (v4.0.4)
- `TERRAFORM_VERSION`: Default Terraform version (1.14.8)
- `TERRAFORM_VERSION_157`: Alternative Terraform version (1.5.7)
- `AWSCLI_VERSION`: AWS CLI v2 version (2.34.30)
- `BOTO3_VERSION`: AWS SDK for Python version (1.42.89)
- `MCP_ATLASSIAN_VERSION`: mcp-atlassian MCP server version (0.21.1)
- `TRIVY_VERSION`: Trivy vulnerability scanner version (v0.70.0)

## Installed Tools

The container includes these pre-installed tools:
- **Claude Code CLI**: AI-powered development assistant
- **AWS CLI v2**: Amazon Web Services command-line interface
- **AWS Session Manager Plugin**: Enables SSM-based EC2 instance access via `aws ssm start-session`
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
- **mcp-atlassian**: Atlassian MCP server for Jira & Confluence integration with Claude Code
- **trivy**: Container and filesystem vulnerability scanner

## mcp-atlassian Configuration

The `mcp-atlassian` binary is pre-installed. To enable it in Claude Code, run once inside the container:

```bash
# Jira + Confluence (cloud, token-based)
claude mcp add atlassian -- mcp-atlassian \
  --confluence-url https://your-org.atlassian.net/wiki \
  --confluence-username your@email.com \
  --confluence-token YOUR_API_TOKEN \
  --jira-url https://your-org.atlassian.net \
  --jira-username your@email.com \
  --jira-token YOUR_API_TOKEN

# Or pass credentials via environment variables (preferred for containers)
claude mcp add atlassian -e CONFLUENCE_URL -e CONFLUENCE_USERNAME \
  -e CONFLUENCE_TOKEN -e JIRA_URL -e JIRA_USERNAME -e JIRA_TOKEN \
  -- mcp-atlassian
```

Since `~/.claude` is a mounted volume, the MCP config persists across container restarts.

## Running with podman play kube (cc-pod.yaml)

The repository includes `cc-pod.yaml` — a Kubernetes pod spec that starts both
`mcp-atlassian` (SSE server sidecar) and `claude-code` (interactive) as a pod.
This is the recommended way to run Claude Code with Atlassian integration.

### Quick start

```bash
# Set Atlassian credentials
export JIRA_URL=https://your-company.atlassian.net
export JIRA_USERNAME=your.email@company.com
export JIRA_API_TOKEN=your_api_token
export CONFLUENCE_URL=https://your-company.atlassian.net/wiki
export CONFLUENCE_USERNAME=your.email@company.com
export CONFLUENCE_API_TOKEN=your_api_token

# From your project directory
./start-cc.sh
```

`start-cc.sh` uses `envsubst` to substitute credentials and paths into
`cc-pod.yaml`, then calls `podman play kube --replace --userns=keep-id`
and attaches to the `claude-code` container.

Alternatively, run manually:

```bash
WORKSPACE_DIR=$(pwd) envsubst < cc-pod.yaml | podman play kube --replace --userns=keep-id -
podman attach cc-claude-code
```

### Pod structure

| Container | Role | Port |
|---|---|---|
| `cc-mcp-atlassian` | mcp-atlassian SSE server | localhost:9000 |
| `cc-claude-code` | Interactive Claude Code CLI | — |

The `cc-claude-code` container waits for `cc-mcp-atlassian` to accept connections
on port 9000 before starting Claude Code.

### Volume mounts (equivalent to podman run flags)

| Host path | Container path |
|---|---|
| `$WORKSPACE_DIR` (current dir) | `/workspace` |
| `~/.claude` | `/home/claude/.claude` |
| `~/.kube` | `/home/claude/.kube` |
| `~/.git-credentials` | `/home/claude/.git-credentials` |

### One-time MCP SSE configuration (first run only)

Inside the pod, configure Claude Code to connect to the mcp-atlassian SSE server:

```bash
claude mcp remove atlassian 2>/dev/null
claude mcp add --transport sse atlassian http://localhost:9000/sse
```

This writes to `~/.claude/` (the mounted volume) so it persists across pod restarts.

### Stop the pod

```bash
podman pod stop cc && podman pod rm cc
```

### Dependencies on host

- `podman` (for running the pod)
- `envsubst` (for credential substitution — `brew install gettext` on macOS)

## Terraform Version Management

The container includes multiple Terraform versions:
- `terraform` (default): Points to Terraform 1.14.3
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

## GitHub and GitLab Integration

The repository includes automated CI/CD via `.github/workflows/build.yml`:
- Builds multi-platform images (linux/amd64, linux/arm64)
- Pushes to GitHub Container Registry (ghcr.io)
- Triggers on pushes to main branch and pull requests
- Uses semantic versioning with branch, PR, and SHA tags

The repository includes automated CI/CD via `.gitlab-ci.yml` for GitLab server:
- Builds multi-platform images (linux/amd64, linux/arm64)
- Pushes to GitHub Container Registry (gitlab.partizani.eu)
- Triggers on pushes to main branch and pull requests

## Development Workflow

1. Make changes to the Dockerfile or supporting files
2. Build locally to test: `podman build -t claude-code-secure .`
3. Run container to verify functionality
4. Push changes to trigger GitHub Actions build

## Environment Variables

The container runs with:
- `SHELL=/bin/bash`: Default shell
- `PYTHONPATH` includes AWS virtual environment for boto3 access
- Working directory set to `/workspace`

## Development Memories

- I expect after adding some new package in the image to build it with podman
and push it to git in order pipeline to create new container image
- When you do upgrade of the image and in order to not halucinate with
fictionary versions of the software packages use Dockerfile to see url that
current one's are downloaded and check new versions there.
- Execute all git commands as a oneliner i.e. commit push tag if there is tag
- If you add some package and need curl | wget download just try to download
locally first and then continue with build











