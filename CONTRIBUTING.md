# Contributing

This tap is maintained by Elastic Field Engineering.

## Formula changes

All formula changes must be submitted through a pull request and pass the
Homebrew test workflow. Formula updates must reference an immutable upstream
release, use SHA-256 checksums, and use locked dependencies for any source
build.

For ESDiag releases:

1. Confirm the upstream GitHub release is published and is not a draft or
   prerelease.
2. Run `scripts/update-esdiag.sh VERSION`, or dispatch the `Update ESDiag`
   workflow with that version.
3. Review every artifact URL and checksum in `Formula/esdiag.rb`.
4. Confirm CI installs and tests every native-binary platform.
5. Merge the pull request. No separate bottle-publishing step is required.

The current CI matrix covers the three native-binary targets. Intel macOS uses
the documented source fallback but is not tested in today's workflow matrix.

The artifact interface between the repositories is documented in
[`docs/esdiag-release-assets.md`](docs/esdiag-release-assets.md).

## Local checks

```sh
bash -n scripts/update-esdiag.sh tests/update-esdiag.sh
shellcheck scripts/update-esdiag.sh tests/update-esdiag.sh
tests/update-esdiag.sh
brew style --formula Formula/esdiag.rb
brew audit --strict --online Formula/esdiag.rb
brew install --build-from-source Formula/esdiag.rb
brew test Formula/esdiag.rb
```

The formula-specific commands apply after `Formula/esdiag.rb` has been
generated from an actual upstream release.
