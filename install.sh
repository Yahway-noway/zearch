#!/usr/bin/env bash
# install.sh - Simple installer for the Python version of Zearch
# Usage: ./install.sh [install_dir] [bin_dir]
# Defaults: $HOME/.local/share/zearch  and  $HOME/.local/bin

set -euo pipefail

INSTALL_DIR="${1:-$HOME/.local/share/zearch}"
BIN_DIR="${2:-$HOME/.local/bin}"
WRAPPER="$BIN_DIR/zearch"

printf '\n==> Installing Zearch (Python)\n'
printf 'Install dir : %s\n' "$INSTALL_DIR"
printf 'Bin dir     : %s\n' "$BIN_DIR"

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# Copy project files (excluding VCS metadata) from current directory
printf '\n==> Copying files...\n'
if command -v rsync >/dev/null 2>&1; then
  rsync -a --exclude '.git' --exclude '__pycache__' --exclude '*.pyc' "$(pwd)/" "$INSTALL_DIR/"
else
  cp -R "$(pwd)"/* "$INSTALL_DIR/"
fi

# Create wrapper script
printf '\n==> Creating wrapper at %s\n' "$WRAPPER"
cat > "$WRAPPER" <<'EOF'
#!/usr/bin/env bash
python "$HOME/.local/share/zearch/main.py" "$@"
EOF
chmod +x "$WRAPPER"

printf '\n✅  Installation complete!\n'
printf 'Add %s to your PATH if it is not already, then run:\n' "$BIN_DIR"
printf '    zearch\n\n'
