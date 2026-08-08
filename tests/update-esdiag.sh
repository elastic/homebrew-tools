#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
TEST_DIR="$(mktemp -d)"
readonly TEST_DIR
trap 'rm -rf "$TEST_DIR"' EXIT

readonly VERSION=1.2.3
readonly RELEASE_DIR="$TEST_DIR/releases/$VERSION"
readonly SOURCE_DIR="$TEST_DIR/sources"
readonly SOURCE_ROOT="$TEST_DIR/source-root/esdiag-$VERSION"
readonly FORMULA_PATH="${ESDIAG_TEST_FORMULA_PATH:-$TEST_DIR/Formula/esdiag.rb}"
readonly TARGETS=(
  aarch64-apple-darwin
  aarch64-unknown-linux-gnu
  x86_64-unknown-linux-gnu
)

mkdir -p "$RELEASE_DIR" "$SOURCE_DIR" "$SOURCE_ROOT" "$TEST_DIR/archive"
printf '%s\n' '#!/usr/bin/env sh' 'echo "esdiag 1.2.3"' > "$TEST_DIR/archive/esdiag"
printf '%s\n' 'test license' > "$TEST_DIR/archive/LICENSE.txt"
printf '%s\n' 'test notice' > "$TEST_DIR/archive/NOTICE.txt"
chmod 755 "$TEST_DIR/archive/esdiag"

for target in "${TARGETS[@]}"; do
  asset="esdiag-${VERSION}-${target}.tar.gz"
  tar -C "$TEST_DIR/archive" -czf "$RELEASE_DIR/$asset" esdiag LICENSE.txt NOTICE.txt
  checksum="$(shasum -a 256 "$RELEASE_DIR/$asset" | awk '{ print $1 }')"
  printf '%s  %s\n' "$checksum" "$asset" >> "$RELEASE_DIR/esdiag-${VERSION}-checksums.txt"
done

printf '%s\n' '[package]' 'name = "esdiag"' 'version = "1.2.3"' > "$SOURCE_ROOT/Cargo.toml"
printf '%s\n' '# synthetic lockfile' > "$SOURCE_ROOT/Cargo.lock"
printf '%s\n' 'test license' > "$SOURCE_ROOT/LICENSE.txt"
printf '%s\n' 'test notice' > "$SOURCE_ROOT/NOTICE.txt"
tar -C "$TEST_DIR/source-root" -czf "$SOURCE_DIR/$VERSION.tar.gz" "esdiag-$VERSION"

ESDIAG_RELEASE_BASE_URL="file://$TEST_DIR/releases" \
  ESDIAG_SOURCE_BASE_URL="file://$SOURCE_DIR" \
  ESDIAG_FORMULA_PATH="$FORMULA_PATH" \
  "$REPO_ROOT/scripts/update-esdiag.sh" "$VERSION"

ruby -c "$FORMULA_PATH" >/dev/null
if [[ ${ESDIAG_TEST_BREW_STYLE:-0} == 1 ]]; then
  brew style --formula "$FORMULA_PATH"
fi
grep -Fq 'on_macos do' "$FORMULA_PATH"
grep -Fq 'on_linux do' "$FORMULA_PATH"
grep -Fq 'depends_on "rust" => :build' "$FORMULA_PATH"
grep -Fq 'system "cargo", "install", *std_cargo_args' "$FORMULA_PATH"

for target in "${TARGETS[@]}"; do
  grep -Fq "esdiag-${VERSION}-${target}.tar.gz" "$FORMULA_PATH"
done

if ESDIAG_RELEASE_BASE_URL="file://$TEST_DIR/releases" \
  ESDIAG_SOURCE_BASE_URL="file://$SOURCE_DIR" \
  ESDIAG_FORMULA_PATH="$FORMULA_PATH" \
  "$REPO_ROOT/scripts/update-esdiag.sh" invalid >/dev/null 2>&1; then
  echo "Updater accepted an invalid version" >&2
  exit 1
fi

echo "ESDiag updater tests passed"
