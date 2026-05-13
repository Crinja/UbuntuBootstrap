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

4. Optional: review the autoinstall example if you want to automate VM OS
   installation before running this bootstrap:

   ```bash
   less installer/autoinstall.example.yaml
   ```

   Keep storage interactive until you are comfortable with the installer flow.

5. Run the bootstrap:

   ```bash
   bash ./bootstrap.sh
   ```

6. Reboot the VM.
7. Run verification:

   ```bash
   ./scripts/verify.sh
   ```

8. Add wrapper commands to PATH:

   ```bash
   echo "source \"$(pwd)/dotfiles/bashrc.append\"" >> ~/.bashrc
   source ~/.bashrc
   ```

9. Create a Rust project environment:

   ```bash
   ws-new rust Terrakit
   ```

10. Enter the Rust environment:

   ```bash
   ws-enter Terrakit
   ```

11. Compile a hello-world Rust project inside the box:

    ```bash
    cd ~/project
    cargo init --bin
    cargo run
    exit
    ```

12. Confirm Rust is not installed on the host:

    ```bash
    command -v rustc && echo "Unexpected host rustc" || echo "No host rustc"
    ```

13. Create a Node project environment:

    ```bash
    ws-new node TestNode
    ws-enter TestNode
    node --version
    npm --version
    exit
    ```

14. Confirm Node is not installed on the host:

    ```bash
    command -v node && echo "Unexpected host node" || echo "No host node"
    ```

15. Re-run the bootstrap to test idempotency:

    ```bash
    bash ./bootstrap.sh
    ```

16. Re-run the Rust project creation to confirm it does not damage the existing
    environment:

    ```bash
    ws-new rust Terrakit
    ```

17. List project environments:

    ```bash
    ws-list
    ```

18. Remove the Node test environment and confirm project files are preserved by
    default:

    ```bash
    ws-remove TestNode
    ls ~/Projects/TestNode
    ```
