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

Project smoke test:

```bash
ws-new rust ExampleProject
flatpak info com.visualstudio.code
ws-code ExampleProject
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

Optional Podman/devcontainer smoke test:

```bash
ws-new node ContainerExample --with-devcontainer
podman info
podman run --rm hello-world
ws-code ContainerExample
```

Optional AI smoke test:

```bash
ws-ai-add ExampleProject --claude
ws-enter ExampleProject
command -v claude
exit
command -v claude && echo "unexpected host claude" || echo "no host claude"
```
