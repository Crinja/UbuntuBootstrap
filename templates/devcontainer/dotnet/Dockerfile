ARG VARIANT=8.0-noble
FROM mcr.microsoft.com/devcontainers/dotnet:1-${VARIANT}

# Pin the SDK for a real project with global.json in the repository.
# Change VARIANT in devcontainer.json when the project moves SDK families.

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    wget \
  && rm -rf /var/lib/apt/lists/*
