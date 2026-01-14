# Use Node.js Alpine LTS - much smaller base image
FROM node:lts-alpine


# Install build dependencies and cleanup in single layer
RUN apk add --no-cache \
    curl \
    vim \
    python3 \
    py3-pip \
    sudo \
    bash \
    git \
    && rm -rf /var/cache/apk/*

# Create non-root user first
RUN adduser -D -s /bin/bash devusr \
    && addgroup devusr wheel \
    && echo 'devusr ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# uv will be installed later as devusr

# Install Go - multi-platform support for amd64 and arm64
ARG TARGETPLATFORM
RUN if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        GO_ARCH="arm64"; \
    else \
        GO_ARCH="amd64"; \
    fi \
    && curl -LO "https://go.dev/dl/go1.24.7.linux-${GO_ARCH}.tar.gz" \
    && tar -C /usr/local -xzf "go1.24.7.linux-${GO_ARCH}.tar.gz" \
    && rm "go1.24.7.linux-${GO_ARCH}.tar.gz" \
    && ln -sf /usr/local/go/bin/go /usr/bin/go

USER devusr
ENV HOME=/home/devusr
# Install Claude Code and uv as devusr
RUN npm config set prefix '~/.npm-global' \
    && npm install -g @anthropic-ai/claude-code@latest \
    && curl -LsSf https://astral.sh/uv/install.sh | sh \
    && rm -rf /tmp/*

# Switch back to root for remaining installations
USER root

# Set PATH for all tools (using literal paths since HOME expands at runtime)
ENV PATH="/usr/local/go/bin:/home/devusr/.local/bin:/home/devusr/.npm-global/bin:/usr/local/bin:$PATH"

# Set working directory
WORKDIR /devbox

# Switch to non-root user
USER devusr

# Set bash as entrypoint to override Node.js default
ENTRYPOINT ["/bin/bash"]

# Default command
CMD ["-c", "while true; do sleep 1000; done"]