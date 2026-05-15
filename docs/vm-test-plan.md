# VM Test Plan

Run this before using the repo on a real install.

```bash
sudo apt update
sudo apt install -y git
git clone <repo-url> UbuntuBootstrap
cd UbuntuBootstrap
bash ./bootstrap.sh
reboot
```

After reboot:

```bash
cd ~/UbuntuBootstrap
./scripts/verify.sh
source ~/.bashrc
```

Confirm the AI tool boxes:

```bash
distrobox-enter --name claude-code -- bash -lc 'command -v claude'
distrobox-enter --name codex -- bash -lc 'command -v codex'
```

Project smoke test:

```bash
ws-new rust ExampleProject
ws-enter ExampleProject
cd ~/project
cargo init --bin
cargo run
exit
```

Host should not have Rust:

```bash
command -v rustc && echo "unexpected host rustc" || echo "no host rustc"
```

Node smoke test:

```bash
ws-new node TestNode
ws-enter TestNode
node --version
npm --version
exit
command -v node && echo "unexpected host node" || echo "no host node"
```

Idempotency:

```bash
bash ./bootstrap.sh
ws-new rust ExampleProject
ws-list
ws-remove TestNode
```

Optional Docker/devcontainer smoke test:

```bash
ws-new node DockerExample --with-devcontainer --with-docker
ws-enter DockerExample
docker --version
docker compose version
exit
command -v docker && echo "unexpected host docker" || echo "no host docker"
```
