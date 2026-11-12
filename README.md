# kandev-bin

Arch User Repository package for the [Kandev CLI](https://github.com/kdlbs/kandev).
It uses the upstream full Linux release bundle for x86_64 and AArch64, including
the helpers for remote agents.

## Install

```sh
paru -S kandev-bin
kandev
```

You can also clone this repository and run `makepkg -si`.

## Release updates

The GitHub Actions workflow checks the latest stable Kandev release every day at
02:23 UTC (10:23 Taipei time). On a new release, it updates the package version
and SHA-256 checksums, regenerates `.SRCINFO` with Arch's `makepkg`, and commits
the changes to the default branch. Run the workflow manually from the Actions
tab to check immediately.

The workflow also syncs `PKGBUILD` and `.SRCINFO` to AUR once the
`AUR_SSH_PRIVATE_KEY` repository secret is configured. Generate a dedicated SSH
key and register its public key on an AUR account authorized to maintain
`kandev-bin`. Add the private key as the GitHub Actions secret. Keep package
changes in this GitHub repository so the next sync carries them to AUR.

To publish manually with an authorized local SSH key, run
`bash scripts/publish-aur.sh`.
