# Elastic Homebrew Tools

Install ESDiag with:

```bash
brew install elastic/tools/esdiag
```

The formula provides pre-built binaries for Apple Silicon macOS and x86_64 or
ARM64 Linux. Intel macOS builds from the tagged source with locked Cargo
dependencies; that fallback is currently best-effort and not covered by CI.

The repository's Apache-2.0 license covers the tap definitions, automation, and
documentation. ESDiag remains licensed under Elastic-2.0, as declared by the
formula and included with the installed package.
