> Creator: whjeong<br>
> Created on: 2026-10-13<br>
> https://maduinos.blogspot.com/

# Release maintenance

This document is for release maintainers. End users should follow the [installation and usage guide](../README.md).

## Repository responsibilities

The development repository remains private. This public repository owns the distribution build, download verification and English deployment page. A read-only source deploy key is stored as the encrypted Actions secret `SOURCE_DEPLOY_KEY`; do not commit its private key.

## Publish a release

1. Update the source package version and push a reviewed source commit. Do not change AMD toolchain versions as part of packaging.
2. Dispatch the release workflow with that full 40-character commit SHA and matching package version.

```bash
gh workflow run release.yml --repo maduinos/amd-fpga-mcp-releases \
  -f source_commit=<full-40-character-source-commit> -f version=<version>
```

3. Check every job: Linux regression/build/install, native Windows PowerShell installer checks, publication, public download verification and page refresh.
4. Check the downloaded assets and the final Pages deployment. A publication job alone is not a successful end-to-end release.

The workflow builds offline wheel bundles with pinned dependency versions and hashes, validates the source version, tests the Windows wrapper before publication, and publishes archive checksums. Published assets are preserved when a release is re-run with matching source provenance; they are never replaced. If package contents need correction, publish a new version.

## Repeat public-download verification

```bash
gh workflow run verify.yml --repo maduinos/amd-fpga-mcp-releases \
  -f version=<version>
```

Linux runners download and install both archive variants and perform actual MCP communication. Windows runners download the ZIP, verify its checksums and exercise the installer with a native executable fixture for WSL commands. This checks real PowerShell argument handling, paths containing spaces, localized status output, WSL1 rejection and error propagation. It does not provision a real WSL2 environment or certify AMD tools and USB/JTAG on a Windows PC.

## Maintain documentation

- `README.md` is the authoritative English user guide. The bundle builder copies it into future distributions; `bundle/` contains installer scripts only.
- `site/index.html` provides a visual introduction, downloads, architecture, workflow summaries and support boundaries. Detailed installation/configuration links go to the README.
- Pages deploys on changes to `site/` or its workflow, and after successful release verification. It renders download links for the latest public release.
- Versioned validation records document evidence for their original version. Do not relabel historical evidence as validation of a newer release.
- Keep the supported host requirements, Windows limitations, tool count and board validation scope consistent across public documents.

For a documentation-only update, commit and push the documentation. Do not rebuild or overwrite existing release archives. Their bundled documentation remains the snapshot at publication time; link users to the current README in release notes.

## Distribution boundaries

Do not publish AMD executables, licenses, credentials, private board configurations or flash backups. Keep the development repository private. Use a dedicated read-only deploy key rather than copying a broad personal access token into CI.
