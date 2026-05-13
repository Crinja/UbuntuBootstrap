FROM ubuntu:24.04

ARG USERNAME=vscode
ARG NVM_VERSION=v0.40.3
ENV DEBIAN_FRONTEND=noninteractive
ENV NVM_DIR="/home/${USERNAME}/.nvm"

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    git \
    sudo \
  && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash "${USERNAME}" \
  && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-vscode \
  && chmod 0440 /etc/sudoers.d/90-vscode

USER "${USERNAME}"
WORKDIR "/home/${USERNAME}"

RUN curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash \
  && bash -lc "source '${NVM_DIR}/nvm.sh' && nvm install --lts && nvm alias default 'lts/*'"

RUN printf '%s\n' \
  'export NVM_DIR="${HOME}/.nvm"' \
  '[ -s "${NVM_DIR}/nvm.sh" ] && . "${NVM_DIR}/nvm.sh"' \
  >>"/home/${USERNAME}/.bashrc"
