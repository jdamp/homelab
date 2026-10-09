# /etc/profile resets PATH for login shells, including Codex's shell setup.
# Restore the pod's BuildKit client and the standard Go binary directories.
export PATH="/builder/bin:/usr/local/go/bin:$HOME/go/bin:$PATH"
