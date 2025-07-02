# Claude Code Container

A containerized version of Claude Code CLI for portable usage across different systems.

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
  ghcr.io/zhecho/claude-code:latest
```

3. **Inside container, run Claude Code**:
```bash
claude --version
claude
```

### Usage Examples

```bash
# Interactive bash session (recommended)
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  ghcr.io/zhecho/claude-code:latest

# Run specific Claude command directly
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  ghcr.io/zhecho/claude-code:latest -c "claude --version"

# One-liner to start Claude interactively
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  ghcr.io/zhecho/claude-code:latest -c "claude"
```

## Volume Mounts

- `/workspace` - Your project directory
- `/home/claude/.claude` - Claude Code config and credentials

## Podman Flags Explained

- `--privileged` - Required for some Claude Code operations
- `--userns=keep-id` - Preserves user/group IDs for file permissions
- `:Z` - SELinux context for shared volumes (Linux systems)
- `-v ./.:/workspace` - Mounts current directory to container workspace

## Building Locally

```bash
# Build image
podman build -t claude-code .

# Run locally built image
podman run --privileged --userns=keep-id --rm -it \
  -v ./.:/workspace \
  -v ~/.claude:/home/claude/.claude:Z \
  claude-code
```
