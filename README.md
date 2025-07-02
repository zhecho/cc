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

2. **Run container**:
```bash
podman run --rm -it \
  -v ./your_project:/workspace \
  -v ~/.claude:/home/claude/.claude \
  ghcr.io/zhecho/claude-code:latest
```

### Usage Examples

```bash
# Interactive mode
podman run --rm -it \
  -v $(pwd):/workspace \
  -v ~/.claude:/home/claude/.claude \
  ghcr.io/zhecho/claude-code:latest

# With arguments
podman run --rm \
  -v $(pwd):/workspace \
  -v ~/.claude:/home/claude/.claude \
  ghcr.io/zhecho/claude-code:latest --help

# Version check
podman run --rm \
  -v ~/.claude:/home/claude/.claude \
  ghcr.io/zhecho/claude-code:latest --version
```

## Volume Mounts

- `/workspace` - Your project directory
- `/home/claude/.claude` - Claude Code config and credentials

## Building Locally

```bash
# Build image
podman build -t claude-code .

# Run locally built image
podman run --rm -it \
  -v $(pwd):/workspace \
  -v ~/.claude:/home/claude/.claude \
  claude-code
```
