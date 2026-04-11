export LANG="${LANG:-C.UTF-8}"

# Ensure user-local binaries are on PATH.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

if [ -n "${BASH_VERSION:-}" ] && [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi
