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
  - Multi-stage build for minimal image size
  - Chainguard Images (Wolfi Linux) base for maximum security and glibc compatibility
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

# Use Terraform (default version 1.12.2)
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  claude-code-secure:latest -c "terraform version"

# Use Terraform 1.5.7 directly
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  claude-code-secure:latest -c "terraform-1.5.7 version"

# Use tfswitch (requires interactive session)
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  claude-code-secure:latest
# Inside container: tfswitch 1.5.7
```

## Terraform Version Management

The container includes multiple Terraform versions and switching capabilities:

### Available Versions
- **terraform** (default): Points to Terraform 1.12.2
- **terraform-1.5.7**: Direct access to Terraform 1.5.7
- **tfswitch**: Official Terraform version switcher

### Usage Examples
```bash
# Check current version
terraform version

# Use specific version directly
terraform-1.5.7 version

# Switch versions using tfswitch (interactive)
tfswitch 1.5.7

# List available versions
tfswitch -l

# Install and switch to latest
tfswitch -u
```

**Note**: tfswitch requires write permissions to /usr/local/bin, so it works best in interactive sessions where you can manage the symlinks in your home directory.

## mcp-atlassian — Jira & Confluence MCP Server

The container ships `mcp-atlassian` (`/usr/local/bin/mcp-atlassian`), giving Claude Code direct access to Jira and Confluence. Configuration is done once via `claude mcp add`; the result is written to `~/.claude/` which is your mounted volume, so it persists across container restarts.

### Option 1: `.env` file (recommended for containers)

Create a file on your host (e.g. `~/.atlassian.env`) — keep it out of git:

```bash
# Atlassian Cloud
JIRA_URL=https://your-org.atlassian.net
JIRA_USERNAME=your@email.com
JIRA_API_TOKEN=your_api_token

CONFLUENCE_URL=https://your-org.atlassian.net/wiki
CONFLUENCE_USERNAME=your@email.com
CONFLUENCE_API_TOKEN=your_api_token

# Server / Data Center (use instead of the above)
# JIRA_URL=https://jira.your-company.com
# JIRA_PERSONAL_TOKEN=your_pat
# JIRA_SSL_VERIFY=false
# CONFLUENCE_URL=https://confluence.your-company.com
# CONFLUENCE_PERSONAL_TOKEN=your_pat
# CONFLUENCE_SSL_VERIFY=false

# Optional filters (comma-separated)
# JIRA_PROJECTS_FILTER=PROJ,DEV
# CONFLUENCE_SPACES_FILTER=DEV,TEAM
# READ_ONLY_MODE=false
```

Register the MCP server inside the container (once):

```bash
claude mcp add atlassian -- mcp-atlassian --env-file /home/claude/.atlassian.env
```

Run the container with the env file mounted:

```bash
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  -v ~/.atlassian.env:/home/claude/.atlassian.env:Z \
  claude-code-secure:latest
```

### Option 2: Environment variables at runtime

Pass credentials directly via `-e` flags — useful in CI or when the env file is managed externally:

```bash
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  -e JIRA_URL=https://your-org.atlassian.net \
  -e JIRA_USERNAME=your@email.com \
  -e JIRA_API_TOKEN=your_api_token \
  -e CONFLUENCE_URL=https://your-org.atlassian.net/wiki \
  -e CONFLUENCE_USERNAME=your@email.com \
  -e CONFLUENCE_API_TOKEN=your_api_token \
  claude-code-secure:latest
```

Register the MCP server to forward those env vars (once):

```bash
claude mcp add atlassian \
  -e JIRA_URL -e JIRA_USERNAME -e JIRA_API_TOKEN \
  -e CONFLUENCE_URL -e CONFLUENCE_USERNAME -e CONFLUENCE_API_TOKEN \
  -- mcp-atlassian
```

### Full list of supported environment variables

| Variable | Purpose |
|---|---|
| `JIRA_URL` | Jira instance URL |
| `JIRA_USERNAME` | Email (Cloud) or username (Server) |
| `JIRA_API_TOKEN` | API token (Cloud) |
| `JIRA_PERSONAL_TOKEN` | Personal Access Token (Server/DC) |
| `JIRA_SSL_VERIFY` | `true`/`false` — disable for self-signed certs |
| `CONFLUENCE_URL` | Confluence instance URL |
| `CONFLUENCE_USERNAME` | Email (Cloud) or username (Server) |
| `CONFLUENCE_API_TOKEN` | API token (Cloud) |
| `CONFLUENCE_PERSONAL_TOKEN` | Personal Access Token (Server/DC) |
| `CONFLUENCE_SSL_VERIFY` | `true`/`false` |
| `JIRA_PROJECTS_FILTER` | Comma-separated project keys to restrict access |
| `CONFLUENCE_SPACES_FILTER` | Comma-separated space keys to restrict access |
| `ENABLED_TOOLS` | Whitelist specific tool names |
| `TOOLSETS` | Enable tool groups: `default`, `all`, or combinations |
| `READ_ONLY_MODE` | `true` disables all write operations |
| `MCP_VERBOSE` | `true` enables verbose logging |
| `HTTP_PROXY` / `HTTPS_PROXY` | Proxy for outbound requests |
| `JIRA_CUSTOM_HEADERS` | Extra HTTP headers (`key=value,key2=value2`) |
| `CONFLUENCE_CUSTOM_HEADERS` | Extra HTTP headers per service |

Full documentation: https://mcp-atlassian.soomiles.com/docs/configuration

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
| Claude Code CLI | 2.1.87                                  | AI-powered development assistant |
| AWS CLI v2 | 2.27.50 | Amazon Web Services command-line interface |
| kubectl | v1.33.2 | Kubernetes command-line tool |
| k9s | v0.50.6 | Kubernetes cluster management UI |
| glab | v1.22.0 | Official GitLab CLI API client |
| git | 2.50.1 | Distributed version control system |
| terraform | 1.12.2 (default) | Infrastructure as Code tool |
| terraform-1.5.7 | 1.5.7 | Alternative Terraform version |
| tfswitch | v1.4.6 | Terraform version switcher |
| boto3 | 1.39.4 | AWS SDK for Python |
| Node.js | 24.4.0 | JavaScript runtime |
| npm | 11.4.2 | Node.js package manager |
| jq | 1.8.1 | JSON processor |
| yq | 4.46.1 | YAML processor |
| curl | Latest | HTTP client |
| binutils | Latest | Binary utilities |
| podman | 5.5.2 | Container runtime |
| skopeo | 1.19.0 | Container image inspector |
| mcp-atlassian | 0.21.1 | Jira & Confluence MCP server for Claude Code |

## Security Features

- **Multi-stage build** reduces final image size and attack surface
- **Non-root user** (UID 1000) for secure container execution
- **Chainguard Images** (Wolfi Linux) for maximum security and zero-CVE target
- **glibc compatibility** enables AWS CLI v2 and modern tooling
- **Proper file permissions** (755 for binaries, 644 for files)
- **Clean package management** with cache removal
- **Security hardening** applied to all installed tools
