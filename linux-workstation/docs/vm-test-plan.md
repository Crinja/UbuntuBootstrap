# VM Test Plan

Use this checklist on a fresh Ubuntu VM before running the bootstrap on a real
machine.

1. Install a fresh Ubuntu 24.04 LTS or newer VM.
2. Install Git:

   ```bash
   sudo apt update
   sudo apt install -y git
   ```

3. Clone this repository:

   ```bash
   git clone <your-repo-url> linux-workstation
   cd linux-workstation
   ```

4. Run the bootstrap:

   ```bash
   bash ./bootstrap.sh
   ```

5. Reboot the VM.
6. Run verification:

   ```bash
   ./scripts/verify.sh
   ```

7. Load the wrapper commands in the current terminal. Bootstrap already added
   them to `~/.bashrc` for new Bash terminals:

   ```bash
   source ~/.bashrc
   ```

8. Configure the optional SDK-free `dev-base` editor box:

   ```bash
   distrobox-enter --name dev-base -- bash -s < boxes/dev-base.sh
   ws-code --base
   ```

9. Confirm the shared AI coding tools box was configured by bootstrap:

   ```bash
   distrobox-enter --name ai-code -- bash -lc 'command -v claude && command -v codex'
   ```

10. Create a Rust project environment:

   ```bash
   ws-new rust Terrakit
   ```

11. Enter the Rust environment:

   ```bash
   ws-enter Terrakit
   ```

12. Compile a hello-world Rust project inside the box:

    ```bash
    cd ~/project
    cargo init --bin
    cargo run
    exit
    ```

13. Confirm Rust is not installed on the host:

    ```bash
    command -v rustc && echo "Unexpected host rustc" || echo "No host rustc"
    ```

14. Optional: run the shared AI tools against the Rust project:

    ```bash
    ws-claude Terrakit
    ws-codex Terrakit
    ```

15. Create a Node project environment:

    ```bash
    ws-new node TestNode
    ws-enter TestNode
    node --version
    npm --version
    exit
    ```

16. Confirm Node is not installed on the host:

    ```bash
    command -v node && echo "Unexpected host node" || echo "No host node"
    ```

17. Re-run the bootstrap to test idempotency:

    ```bash
    bash ./bootstrap.sh
    ```

18. Re-run the Rust project creation to confirm it does not damage the existing
    environment:

    ```bash
    ws-new rust Terrakit
    ```

19. List project environments:

    ```bash
    ws-list
    ```

20. Remove the Node test environment and confirm project files are preserved by
    default:

    ```bash
    ws-remove TestNode
    ls ~/Projects/TestNode
    ```
