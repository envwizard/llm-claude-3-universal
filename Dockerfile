FROM ubuntu:22.04

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /workspace

# Install git if not present (most base images have it, but just in case)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Clone repository
RUN git clone https://github.com/simonw/llm-claude-3.git /workspace/llm-claude-3 && cd /workspace/llm-claude-3 && git checkout c62bf247fa964ff350badf5424743ddca7601d4a

WORKDIR /workspace/llm-claude-3

# Create script to copy repository content to workspace
RUN echo '#!/bin/bash' > /usr/local/bin/copy-repo.sh && \
    echo 'if [ -d "/workspaces" ] && [ "$(ls -A /workspaces 2>/dev/null | wc -l)" -eq "0" ]; then' >> /usr/local/bin/copy-repo.sh && \
    echo '  echo "Copying repository content to workspace..."' >> /usr/local/bin/copy-repo.sh && \
    echo '  cp -r /workspace/llm-claude-3/. /workspaces/ 2>/dev/null || true' >> /usr/local/bin/copy-repo.sh && \
    echo 'fi' >> /usr/local/bin/copy-repo.sh && \
    chmod +x /usr/local/bin/copy-repo.sh

# Setup script
RUN echo '#!/bin/bash' > /tmp/setup.sh && \
    echo 'set -e' >> /tmp/setup.sh && \
    echo "# Install system dependencies" >> /tmp/setup.sh && \
    echo "apt-get update && apt-get install -y python3 python3-pip python3-venv python3-dev git curl wget build-essential libssl-dev libffi-dev pkg-config ca-certificates" >> /tmp/setup.sh && \
    echo "rm -rf /var/lib/apt/lists/*" >> /tmp/setup.sh && \
    echo "# Set up Python 3 as default python" >> /tmp/setup.sh && \
    echo "update-alternatives --install /usr/bin/python python /usr/bin/python3 1" >> /tmp/setup.sh && \
    echo "update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1" >> /tmp/setup.sh && \
    echo "# Install the project dependencies" >> /tmp/setup.sh && \
    echo "pip install ." >> /tmp/setup.sh && \
    echo "# Install additional useful tools for development" >> /tmp/setup.sh && \
    echo "pip install pytest pytest-recording black ruff mypy" >> /tmp/setup.sh && \
    echo "# Create useful aliases" >> /tmp/setup.sh && \
    echo "echo 'alias ll=\"ls -la\"' >> ~/.bashrc" >> /tmp/setup.sh && \
    echo "echo 'alias la=\"ls -la\"' >> ~/.bashrc" >> /tmp/setup.sh && \
    echo "echo 'alias ..=\"cd ..\"' >> ~/.bashrc" >> /tmp/setup.sh && \
    echo "echo 'alias ...=\"cd ../..\"' >> ~/.bashrc" >> /tmp/setup.sh && \
    echo "echo 'cd /workspace/llm-claude-3' >> ~/.bashrc" >> /tmp/setup.sh && \
    echo "# Create welcome message" >> /tmp/setup.sh && \
    echo "echo '#!/bin/bash' > /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"🚀 Welcome to the llm-claude-3 development environment!\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"📁 Working directory: \$(pwd)\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"🐍 Python version: \$(python --version)\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"Available commands:\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"  llm models                    - List available LLM models\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"  llm -m claude-3.5-sonnet ... - Run Claude 3.5 Sonnet\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"  pytest                       - Run tests\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"  black .                      - Format code\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"  ruff check .                 - Lint code\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"To set up your Anthropic API key:\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "echo 'echo \"  llm keys set claude\"' >> /workspace/welcome.sh" >> /tmp/setup.sh && \
    echo "chmod +x /workspace/welcome.sh" >> /tmp/setup.sh && \
    chmod +x /tmp/setup.sh && \
    /tmp/setup.sh

# Create user developer
RUN useradd -m -s /bin/bash developer
USER developer

EXPOSE 8000
EXPOSE 8080
EXPOSE 3000