# Red Hat icons: attribution and provenance

The Red Hat artwork under `svg\redhat\` is by **Red Hat, Inc.**, obtained from the
[official Red Hat Icons repository](https://github.com/RedHat-UX/red-hat-icons).
The upstream package is `@rhds/icons`, version **2.3.1**.

## Source and license

- Pinned source commit: [`d4f3eaa75084faa0025a3f82cde4d4796b7e056e`](https://github.com/RedHat-UX/red-hat-icons/tree/d4f3eaa75084faa0025a3f82cde4d4796b7e056e).
- Icon artwork license: [Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/).
- Full upstream artwork license: [red-hat-icons\license-icons.md](red-hat-icons/license-icons.md).
- Separate MIT software license: [red-hat-icons\license-software.md](red-hat-icons/license-software.md).
- Original upstream README: [red-hat-icons\upstream-readme.md](red-hat-icons/upstream-readme.md).

**The repository's MIT software license is not the artwork license.** Retain attribution,
the artwork license, and source links when redistributing these icons. Trademark rights
are not granted by CC BY 4.0, and inclusion here does not imply Red Hat endorsement.

The SVG bytes are unchanged. Only their filenames and repository organization differ
from upstream. No icons were redrawn, recolored, optimized, rasterized, or generated.
The catalog records a pinned source URL, revision, license, attribution, and SHA-256
for every imported icon.

## Included sets

| Upstream set | Count | Local directory | Kind |
| --- | ---: | --- | --- |
| Standard brand/diagram icons | 555 | `svg\redhat\standard\` | `resource` |
| User-interface icons | 603 | `svg\redhat\ui\` | `ui` |
| Small-interface microns | 35 | `svg\redhat\microns\` | `ui` |

Examples include containers, container registries, Kubernetes pods, clusters, servers,
virtual infrastructure, automation, AI models, AI inference, and MCP servers.
The upstream set name is preserved as `category` and `--style-<set>`, so similarly named
icons in different sets remain distinct. Upstream suffixes such as `-fill` remain in
the descriptive component name. No nominal size is inferred from the SVG view box.

Only original SVGs are supplied by this source. There is deliberately no generated
`png\redhat\` directory. The 36 upstream social icons are excluded because this import
is for Red Hat brand, diagram, and UI artwork, not another collection of third-party
social-network logos.

## Product icons are a separate collection

Generic icons such as `container`, `automation`, and `hat` are not relabeled as
OpenShift, Ansible, RHEL, or corporate logos.

Red Hat's [technology-icon guidance](https://www.redhat.com/en/about/brand/standards/icons/technology-icons)
links to a separate [Adobe Brand Portal kit](https://redhat.brand-portal.adobe.com/mediaportal.html/content/dam/mac/redhat/brand/icons/technology-icons).
That download required authentication when checked on 2026-10-26, so its artwork is
not included and its redistribution rights are not assumed from this library's license.
An authorized export and its applicable terms would be needed for a later import.

For usage context, consult the official
[standard-icon guidance](https://www.redhat.com/en/about/brand/standards/icons/standard-icons)
and [design-system icon documentation](https://ux.redhat.com/elements/icon/).

## Reproducing this import

Download the pinned archive without installing or executing upstream software:

```powershell
$archive = Join-Path $env:TEMP 'redhat-brand-icons-d4f3eaa.zip'
Invoke-WebRequest -Uri 'https://codeload.github.com/RedHat-UX/red-hat-icons/zip/d4f3eaa75084faa0025a3f82cde4d4796b7e056e' -OutFile $archive
.\scripts\import-redhat-icons.ps1 -ArchivePath $archive
.\scripts\manage-icons.ps1 -Mode Build
.\scripts\manage-icons.ps1 -Mode Validate
```

Regression checks for this importer can be run with
`.\scripts\test-import-redhat-icons.ps1 -ArchivePath $archive -WorkDirectory $env:TEMP`.

Expected archive SHA-256:
`9d3b73ba67658966d04fd36de2da3f88697cc3b93450d40821e512e31bd63b1c`.
The importer checks the archive checksum, exact set counts, naming collisions, existing
contents, and provenance before writing. Reimporting the pinned archive is idempotent.
Changing the pinned source requires reviewing the artwork license, counts, and checksum.
