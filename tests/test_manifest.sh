#!/usr/bin/env bash
set -euo pipefail
forge=${1:-./build/forge}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export HOME="$tmp/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
mkdir -p "$HOME"
"$forge" setup >/dev/null
"$forge" config get prefix | grep -F "$HOME/.local" >/dev/null
"$forge" repo list | grep -F official >/dev/null
if "$forge" config set prefix relative-path >/dev/null 2>&1; then
  echo "relative prefix unexpectedly accepted" >&2
  exit 1
fi
mkdir -p "$XDG_DATA_HOME/forge/catalog"
printf '#commit\tdeadbeef\nhello-world\tpackages/hello-world/forge.pkg\n' > "$XDG_DATA_HOME/forge/catalog/official"
"$forge" search hello | grep -F hello-world >/dev/null
"$forge" repo validate | grep -F '1 catalog entry' >/dev/null
echo "CLI smoke tests passed"
