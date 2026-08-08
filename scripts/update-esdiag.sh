#!/usr/bin/env bash

set -euo pipefail

readonly VERSION_PATTERN='^[0-9]+\.[0-9]+\.[0-9]+$'
readonly DEFAULT_RELEASE_BASE_URL='https://github.com/elastic/esdiag/releases/download'
readonly DEFAULT_SOURCE_BASE_URL='https://github.com/elastic/esdiag/archive/refs/tags'
readonly RELEASE_BASE_URL="${ESDIAG_RELEASE_BASE_URL:-${DEFAULT_RELEASE_BASE_URL}}"
readonly SOURCE_BASE_URL="${ESDIAG_SOURCE_BASE_URL:-${DEFAULT_SOURCE_BASE_URL}}"
readonly FORMULA_PATH="${ESDIAG_FORMULA_PATH:-Formula/esdiag.rb}"
readonly TARGETS=(
  aarch64-apple-darwin
  aarch64-unknown-linux-gnu
  x86_64-unknown-linux-gnu
)

usage() {
  echo "Usage: $0 MAJOR.MINOR.PATCH" >&2
}

if [[ $# -ne 1 ]] || [[ ! $1 =~ ${VERSION_PATTERN} ]]
then
  usage
  exit 2
fi

readonly VERSION="$1"
readonly VERSION_URL="${RELEASE_BASE_URL}/${VERSION}"
readonly SOURCE_URL="${SOURCE_BASE_URL}/${VERSION}.tar.gz"
readonly CHECKSUM_ASSET="esdiag-${VERSION}-checksums.txt"
WORK_DIR="$(mktemp -d)"
readonly WORK_DIR
trap 'rm -rf "$WORK_DIR"' EXIT

curl -fsSL "${VERSION_URL}/${CHECKSUM_ASSET}" -o "${WORK_DIR}/checksums.txt"

checksum_for() {
  local asset="$1"
  local matches
  local match_count
  local checksum

  matches="$(awk -v asset="${asset}" '$2 == asset || $2 == "*" asset { print $1 }' "${WORK_DIR}/checksums.txt")"
  match_count="$(awk 'NF { count++ } END { print count + 0 }' <<<"${matches}")"
  if [[ ${match_count} -ne 1 ]]
  then
    echo "Expected exactly one checksum for ${asset}" >&2
    return 1
  fi

  checksum="$(printf '%s\n' "${matches}" | awk 'NF { print; exit }')"
  if [[ ! ${checksum} =~ ^[0-9a-f]{64}$ ]]
  then
    echo "Invalid SHA-256 for ${asset}" >&2
    return 1
  fi

  printf '%s' "${checksum}"
}

verify_archive() {
  local asset="$1"
  local checksum="$2"
  local archive="${WORK_DIR}/${asset}"
  local listing="${WORK_DIR}/${asset}.list"
  local extract_dir="${WORK_DIR}/${asset}.extract"
  local required

  curl -fsSL "${VERSION_URL}/${asset}" -o "${archive}"
  printf '%s  %s\n' "${checksum}" "${archive}" | shasum -a 256 --check --status
  tar -tzf "${archive}" >"${listing}"

  for required in esdiag LICENSE.txt NOTICE.txt
  do
    if ! grep -Fqx "${required}" "${listing}"
    then
      echo "${asset} does not contain required root file: ${required}" >&2
      return 1
    fi
  done

  mkdir -p "${extract_dir}"
  tar -xzf "${archive}" -C "${extract_dir}" esdiag
  if [[ ! -x "${extract_dir}/esdiag" ]]
  then
    echo "${asset} contains a non-executable esdiag binary" >&2
    return 1
  fi
}

verify_source_archive() {
  local archive="${WORK_DIR}/esdiag-${VERSION}-source.tar.gz"
  local archive_root="esdiag-${VERSION}"
  local listing="${WORK_DIR}/esdiag-${VERSION}-source.list"
  local required

  curl -fsSL "${SOURCE_URL}" -o "${archive}"
  SOURCE_SHA256="$(shasum -a 256 "${archive}" | awk '{ print $1 }')"
  readonly SOURCE_SHA256
  tar -tzf "${archive}" >"${listing}"

  for required in Cargo.toml Cargo.lock LICENSE.txt NOTICE.txt
  do
    if ! grep -Fqx "${archive_root}/${required}" "${listing}"
    then
      echo "Source archive does not contain required file: ${required}" >&2
      return 1
    fi
  done

  if ! tar -xOzf "${archive}" "${archive_root}/Cargo.toml" | grep -Fqx "version = \"${VERSION}\""
  then
    echo "Source archive Cargo.toml does not declare version ${VERSION}" >&2
    return 1
  fi
}

for target in "${TARGETS[@]}"
do
  asset="esdiag-${VERSION}-${target}.tar.gz"
  checksum="$(checksum_for "${asset}")"
  verify_archive "${asset}" "${checksum}"

  case "${target}" in
    aarch64-apple-darwin) readonly MACOS_ARM_SHA256="${checksum}" ;;
    aarch64-unknown-linux-gnu) readonly LINUX_ARM_SHA256="${checksum}" ;;
    x86_64-unknown-linux-gnu) readonly LINUX_INTEL_SHA256="${checksum}" ;;
    *)
      echo "Unsupported target: ${target}" >&2
      exit 1
      ;;
  esac
done

verify_source_archive

mkdir -p "$(dirname "${FORMULA_PATH}")"

formula_tmp="${WORK_DIR}/esdiag.rb"
{
  printf '%s\n' 'class Esdiag < Formula'
  printf '%s\n' '  desc "Collect and process Elastic Stack diagnostic bundles"'
  printf '%s\n' '  homepage "https://github.com/elastic/esdiag"'
  printf '%s\n' '  license "Elastic-2.0"'
  printf '\n%s\n' '  livecheck do'
  printf '%s\n' '    url :stable'
  printf '%s\n' '    strategy :github_latest'
  printf '%s\n\n' '  end'
  printf '%s\n' '  on_macos do'
  printf '%s\n' '    on_arm do'
  printf '      url "%s/esdiag-%s-aarch64-apple-darwin.tar.gz"\n' "${VERSION_URL}" "${VERSION}"
  printf '      sha256 "%s"\n' "${MACOS_ARM_SHA256}"
  printf '%s\n' '    end'
  printf '\n%s\n' '    on_intel do'
  printf '      url "%s"\n' "${SOURCE_URL}"
  printf '      sha256 "%s"\n' "${SOURCE_SHA256}"
  printf '\n%s\n' '      depends_on "rust" => :build'
  printf '%s\n' '    end'
  printf '%s\n\n' '  end'
  printf '%s\n' '  on_linux do'
  printf '%s\n' '    on_arm do'
  printf '      url "%s/esdiag-%s-aarch64-unknown-linux-gnu.tar.gz"\n' "${VERSION_URL}" "${VERSION}"
  printf '      sha256 "%s"\n' "${LINUX_ARM_SHA256}"
  printf '%s\n' '    end'
  printf '\n%s\n' '    on_intel do'
  printf '      url "%s/esdiag-%s-x86_64-unknown-linux-gnu.tar.gz"\n' "${VERSION_URL}" "${VERSION}"
  printf '      sha256 "%s"\n' "${LINUX_INTEL_SHA256}"
  printf '%s\n' '    end'
  printf '%s\n\n' '  end'
  printf '%s\n' '  def install'
  printf '%s\n' '    if (buildpath/"Cargo.toml").exist?'
  printf '%s\n' '      ENV["ESDIAG_GENERATE_NOTICE"] = "0"'
  printf '%s\n' '      system "cargo", "install", *std_cargo_args'
  printf '%s\n' '    else'
  printf '%s\n' '      bin.install "esdiag"'
  printf '%s\n' '    end'
  printf '%s\n' '    prefix.install "LICENSE.txt", "NOTICE.txt"'
  printf '%s\n\n' '  end'
  printf '%s\n' '  test do'
  printf '%s\n' '    assert_match version.to_s, shell_output("#{bin}/esdiag --version")'
  printf '%s\n' '  end'
  printf '%s\n' 'end'
} >"${formula_tmp}"

ruby -c "${formula_tmp}" >/dev/null
mv "${formula_tmp}" "${FORMULA_PATH}"

echo "Updated ${FORMULA_PATH} for ESDiag ${VERSION}"
