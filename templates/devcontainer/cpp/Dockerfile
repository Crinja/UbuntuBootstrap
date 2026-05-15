FROM ubuntu:24.04

ARG USERNAME=vscode
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    clang \
    clang-format \
    cmake \
    curl \
    gdb \
    git \
    lldb \
    ninja-build \
    pkg-config \
    sudo \
    valgrind \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash "${USERNAME}" \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-vscode \
  && chmod 0440 /etc/sudoers.d/90-vscode

USER "${USERNAME}"
WORKDIR "/home/${USERNAME}"
