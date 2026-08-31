# ESDiag release artifact contract

`homebrew-tools` consumes native binaries published by `elastic/esdiag` on
Apple Silicon and Linux. On Intel macOS, it builds the tagged ESDiag source. It
does not modify the upstream release.

## Required release

The GitHub release must:

- use a stable `MAJOR.MINOR.PATCH` tag without a leading `v`;
- be published, not a draft or prerelease;
- contain all three archives and one aggregate checksum file below; and
- keep release assets immutable after publication.

## Required assets

For version `VERSION`, publish:

| Platform | Rust target | Archive |
| --- | --- | --- |
| macOS Apple Silicon | `aarch64-apple-darwin` | `esdiag-VERSION-aarch64-apple-darwin.tar.gz` |
| Linux ARM64 | `aarch64-unknown-linux-gnu` | `esdiag-VERSION-aarch64-unknown-linux-gnu.tar.gz` |
| Linux x86-64 | `x86_64-unknown-linux-gnu` | `esdiag-VERSION-x86_64-unknown-linux-gnu.tar.gz` |

Also publish `esdiag-VERSION-checksums.txt` with lowercase SHA-256 records in the
format emitted by `sha256sum`:

```text
<64 lowercase hex characters>  esdiag-VERSION-aarch64-apple-darwin.tar.gz
```

The checksum file must contain exactly one record for every required archive.
Additional release assets are allowed.

## Archive contents

Every `.tar.gz` archive must contain these files at its root:

```text
esdiag
LICENSE.txt
NOTICE.txt
```

`esdiag` must be executable and `esdiag --version` must report `VERSION`. The
macOS binaries must be compatible with the minimum macOS version supported by
the ESDiag maintainers. Linux binaries must use glibc and run on Homebrew's
supported Linux environments.

## Intel macOS source fallback

Intel macOS uses GitHub's tagged source archive:

```text
https://github.com/elastic/esdiag/archive/refs/tags/VERSION.tar.gz
```

The updater verifies that the archive contains `Cargo.toml`, `Cargo.lock`,
`LICENSE.txt`, and `NOTICE.txt`, and that the package version matches `VERSION`.
The formula declares Rust as a build-only dependency and installs with Cargo's
locked dependency graph. Notice regeneration is disabled because the tagged
source already contains `NOTICE.txt`.

The Intel source-build path is not included in the current CI runner matrix and
is therefore best-effort until dedicated Intel testing is added.

## Tap update

Updating this tap is a required post-publication step in the ESDiag release
process. The release operator runs:

```sh
scripts/update-esdiag.sh VERSION
```

The updater downloads and verifies every binary archive and the tagged source,
validates their layouts, and renders `Formula/esdiag.rb`. The release operator
then runs the repository tests and opens a pull request using their GitHub
identity so the normal pull-request checks run.

`Update ESDiag` is a manually dispatched recovery workflow, not a release
discovery mechanism. It requires an explicit stable version and opens an update
pull request when no update for that version already exists.
