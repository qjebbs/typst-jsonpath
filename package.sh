#!/usr/bin/env bash

files=(
  src/
  typst.toml
  LICENSE
  README.md
)

ARGS=()
FLAG_HELP=false
while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help)
      FLAG_HELP=true
      shift
      ;;
    -*)
      echo "Unexpected option $1!"
      exit 1
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

if $FLAG_HELP; then
  echo "package.sh [TARGET]"
  echo ""
  echo "Packages relevant files into directory '<TARGET>/<PKG_NAME>/<PKG_VERSION>'"
  echo "If TARGET is not set, the local Typst package directory which is"
  echo "'<DATA_DIR>/typst/package/local' will be used."
  exit 1
fi

function read_toml() {
  local file="$1"
  local key="$2"
  # Read a key value pair in the format: <key> = "<value>"
  # stripping surrounding quotes.
  perl -lne "print \"\$1\" if /^${key}\\s*=\\s*\"(.*)\"/" < "$file"
}

PKG_ROOT="${PKG_ROOT:-${PWD}}"
if [ ! -f "$PKG_ROOT/typst.toml" ]; then
  echo "Could not find typst.toml at PKG_ROOT ($PKG_ROOT)!"
  exit 1
fi

PKG_NAME="$(read_toml "$PKG_ROOT/typst.toml" "name")"
if [ -z "$PKG_NAME" ]; then
  echo "Could not read 'name' from $PWD/typst.toml!"
  exit 1
fi

PKG_VERSION="$(read_toml "$PKG_ROOT/typst.toml" "version")"
if [ -z "$PKG_VERSION" ]; then
  echo "Could not read 'version' from $PWD/typst.toml!"
  exit 1
fi

echo "Package root:    $PKG_ROOT"
echo "Package name:    $PKG_NAME"
echo "Package version: $PKG_VERSION"

# Local package directories per platform
if [[ "$OSTYPE" == "linux"* ]]; then
  DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  DATA_DIR="$HOME/Library/Application Support"
else
  DATA_DIR="${APPDATA}"
fi

TARGET=${ARGS[0]}

if [ -z "$TARGET" ]; then
  TARGET="${DATA_DIR}/typst/packages/local"
fi
echo "Install dir: $TARGET"

TMP="$(mktemp -d)"

for f in "${files[@]}"; do
  mkdir -p "$TMP/$(dirname "$f")" 2>/dev/null
  cp -r "$PKG_ROOT/$f" "$TMP/$f"
done

TARGET="${TARGET}/${PKG_NAME}/${PKG_VERSION}"
if rm -rf "${TARGET}" 2>/dev/null; then
  echo "Overwriting existing version."
fi

mkdir -p "$TARGET"
mv "$TMP"/* "$TARGET"

echo "Packaged to: $TARGET"