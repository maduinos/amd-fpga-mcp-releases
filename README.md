> Creator: whjeong<br>
> Created on: 2026-10-13<br>
> https://maduinos.blogspot.com/

# AMD FPGA MCP releases

Public distribution repository. The development repository remains private.

- [English installation and usage page](https://maduinos.github.io/amd-fpga-mcp-releases/)
- [Download releases](https://github.com/maduinos/amd-fpga-mcp-releases/releases)
- Linux x86_64 and Windows x86_64 with a WSL2 Linux backend; Python 3.12.

Maintainers: dispatch `release.yml` with a full reviewed source commit SHA and matching package version.
A read-only source deploy key is stored as `SOURCE_DEPLOY_KEY`. The workflow tests the exact source, builds offline wheel bundles, verifies installation, publishes checksums and downloads the public assets again.
Linux CI installs both archive variants and checks MCP communication. Windows CI verifies the downloaded ZIP and PowerShell wrapper forwarding. Full WSL2 installation/reboot and USB/JTAG on Windows require user-machine validation.
Pages deploy automatically when `site/` changes and after a successfully verified release. Download links are rendered for the latest public version. Release publication is manual dispatch, preventing an unreviewed push from becoming a public package.

Example release command after pushing the corresponding source version:
```bash
gh workflow run release.yml --repo maduinos/amd-fpga-mcp-releases \
  -f source_commit=<full-40-character-source-commit> -f version=<version>
```
Repeat a published-download check with `gh workflow run verify.yml --repo maduinos/amd-fpga-mcp-releases -f version=<version>`.
Re-running a release preserves existing public assets if their source provenance matches; it never replaces a published archive.
No vendor executables, credentials, flash backups or private board configurations are distributed.
