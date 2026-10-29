# Vendor icons

Vendor artwork organized for filename search, diagrams, presentations, and AI agents.
Original icon contents are preserved; renaming does not change artwork or usage rights.
`.gitattributes` disables automatic line-ending conversion so clones preserve the
original file bytes and recorded checksums on every platform.

## Layout

| Folder | Contents |
| --- | --- |
| `svg\` | SVG assets, grouped by vendor and then product family/category |
| `png\` | PNG counterparts using the same organization and basenames |
| `catalog\icons.json` | Searchable icon metadata, aliases, dimensions, variants, and checksums |
| `catalog\migration.csv` | Original-file mapping, removed metadata inventory, and generated-file derivations |
| `docs\vendors\` | Original vendor documentation, terms, licenses, and reference images |
| `upstream\` | Retained non-icon package files, metadata, manifests, and source artwork |
| `scripts\` | PowerShell 7.4+ maintenance tooling; format synchronization also uses pinned resvg |

Every cataloged icon has both SVG and PNG counterparts. Existing vendor
categories are retained, not mapped to a speculative cross-vendor taxonomy.

## Naming

```text
<vendor>-[<family>-]<kind>[-<component>][--style-<style>][--theme-<theme>][--size-<size>][--scale-<scale>].<format>
```

Names use lowercase kebab-case. Vendor identifiers are `aws`, `microsoft`, `google`,
`mongodb`, `capgemini`, `redhat`, and `mcp`; Microsoft families are `azure`, `fabric`,
`fluent`, `copilot`, and `power-platform`. MongoDB product
families are retained where applicable. Kinds are `service`, `resource`, `category`,
`group`, `ui`, and `logo`. Parent-service context is retained in resource names.

Examples:

```text
aws-service-amazon-workspaces--size-32.svg
aws-resource-iot-action--size-48.png
microsoft-azure-service-batch-ai.svg
microsoft-fabric-ui-add-pipeline--style-non-item--size-20.svg
google-service-compute-engine--style-color--size-512.png
capgemini-logo--style-201x.svg
redhat-resource-container--style-standard.svg
```

The size suffix preserves the vendor's nominal size label, including SVG variants.
It does not promise actual raster dimensions; consult the catalog's `image` fields.
SVG width/height attributes are retained as strings with their original units, and
`view_box` is recorded separately. PNG width/height values are actual pixel dimensions.
AWS high-density exports retain an additional `--scale-5x` suffix.
Matching source variants across formats share a basename. Source color-space labels
such as `rgb` are recorded in `variants.color_space` rather than treated as artwork styles.
Distinct Azure IDs that otherwise collide receive `--source-id-<id>` suffixes.
Other source IDs and original release-folder names remain in the catalog/mapping.
Historical service names are not silently replaced with newer product names.

## Finding an icon

Search a filename first, then consult the catalog for synonyms and variants:

```powershell
Get-ChildItem -LiteralPath .\svg -Recurse -File -Filter '*compute-engine*'
$catalog = Get-Content -LiteralPath .\catalog\icons.json -Raw | ConvertFrom-Json
$catalog.icons |
    Where-Object { $_.name -like '*gke*' -or ($_.aliases -join ' ') -like '*Kubernetes*' } |
    Select-Object name, path, format, image
```

Catalog paths are repository-relative Windows paths. Each record describes one file,
not a service abstracted across formats. Aliases include original filenames and available
source captions, with a small set of explicit acronym expansions. They are not inferred
claims that one product supersedes another.

## Synchronized formats

Original artwork and original PNG sizes remain unchanged. Where an upstream SVG had
no PNG, an additional PNG was rendered at a **512-pixel longest edge**, preserving its
aspect ratio and transparency. This is a bounding box, not a forced 512 x 512 square.
Every canonical variant has matching SVG/PNG paths and basenames.

The 331 AWS `--scale-5x` PNG variants already had corresponding base SVGs. Their SVG
counterparts are byte-identical copies of those vectors with matching variant names,
not traced artwork or raster images wrapped in SVG.

Generated records carry a `derivation` object with the source path/checksum, method,
renderer, and requested longest edge. In the mapping, they use `action=generate` and
a synthetic `Generated\...` original path rather than claiming to be upstream exports.
Source attribution and license metadata are inherited where available. Generated
counterparts remain subject to the original vendor's applicable terms.

To synchronize future imports, obtain the official
[resvg 0.49.0 Windows x64 ZIP](https://github.com/linebender/resvg/releases/download/v0.49.0/resvg-win-x86_64.zip)
and extract `resvg.exe` outside the repository:

- ZIP SHA-256: `38af9631b37e61118a32a5ef31e6be6af083eda63b4c17ffc4fdc63e449277df`.
- Executable SHA-256: `266b45d69cd80aafbd7ff2b6424a6a6c2e476888a535a4ce38d5a055bed95624`.

Verify the ZIP hash before extraction. The synchronization script verifies the executable
hash before running it; renderer binaries and archives should not be committed.

```powershell
.\scripts\sync-icon-formats.ps1 -RendererPath 'C:\tools\resvg\resvg.exe'
.\scripts\manage-icons.ps1 -Mode Build
.\scripts\manage-icons.ps1 -Mode Validate -RequirePairs
```

The synchronizer preserves all existing assets, stages new outputs before installation,
refuses conflicting destinations, and is idempotent. It fails if a PNG-only asset lacks
a known base vector rather than inventing vector artwork. Regression checks:
`.\scripts\test-sync-icon-formats.ps1 -RendererPath 'C:\tools\resvg\resvg.exe' -WorkDirectory $env:TEMP`.

## Provenance and rights

Vendor artwork remains subject to its respective terms. This collection does not
grant a blanket license or imply that all vendors use the same license.

- Azure terms and FAQ: `docs\vendors\microsoft\azure\`.
- Fabric license and upstream README: `docs\vendors\microsoft\fabric\`.
- MongoDB extraction provenance and usage notes: `docs\vendors\mongodb\readme.md`.
- MongoDB original slide manifest: `upstream\mongodb\manifest.csv`. Its paths refer to
  the original extraction layout; use `catalog\migration.csv` to resolve current paths.
- MongoDB contact sheet: `docs\vendors\mongodb\contact-sheet.png`, not an individual icon.
- Red Hat attribution, CC BY 4.0 artwork license, source links, and import instructions:
  `docs\vendors\redhat\README.md`. Includes 1,193 original SVGs across the standard,
  UI, and microns sets, plus generated PNG counterparts; the separately distributed
  product-technology kit is not included.
- Fluent UI artwork license: `docs\vendors\microsoft-fluent\LICENSE`.
- Copilot and Copilot Studio source and usage caveats:
  `docs\vendors\microsoft-copilot\USAGE.md` and
  `docs\vendors\microsoft-product\USAGE.md`.
- Model Context Protocol mark and trademark caveats: `docs\vendors\mcp\USAGE.md`.

The additions archive contributes 76 cataloged SVG/PNG files, preserved byte-for-byte.
Its original manifest and README are retained under `upstream\vendor-icons-additions\`;
the manifest records retrieval dates, source URLs, licenses, and the original PNG
rendering/alpha-recovery methods. These imported PNGs were not regenerated with resvg.
Three PNG-only variants (the two `microsoft-product-logo-*` files and the Microsoft 365
Copilot `--style-m365-badge` variant) are retained under that directory's original
`png\microsoft\` layout as source artwork, not cataloged icons. No matching vector was
supplied; no SVG was invented or substituted. All 85 imported files are tracked in the
migration mapping. Archived documents and manifest paths describe the original archive
layout; use that mapping to find their retained locations.

MongoDB presentation-kit SVGs contain embedded PNG artwork, not reconstructed vectors.
The catalog marks these as `raster-embedded`; do not substitute the standalone brand
logo for an Atlas/product-family icon. Read the original usage guidance.

Downloaded Red Hat records include a `source` object with a pinned upstream URL,
revision, artwork license, and attribution. Earlier imported vendors retain their
original provenance fields; missing source-license metadata is not a grant of rights.

Upstream JavaScript/TypeScript files and package metadata are retained for provenance,
not offered as a working npm package after the artwork has been relocated. Original
vendor READMEs are also preserved as historical documents; their relative links and
import examples may refer to the original package layout.

## Maintenance

Run from the repository root with PowerShell 7.4 or later:

```powershell
.\scripts\manage-icons.ps1 -Mode Build
.\scripts\manage-icons.ps1 -Mode Validate -RequirePairs
```

If local execution policy blocks unsigned scripts, invoke each command in a separate
process as `pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\manage-icons.ps1 -Mode Validate`
(substituting the desired mode). This does not change the persistent execution policy.

`Build` regenerates the catalog deterministically from the checked-in migration mapping.
`Validate` checks all original/generated file hashes, derivations, catalog coverage,
naming, image metadata, absence of original vendor folders, and absence of macOS
packaging debris. `-RequirePairs` also rejects any icon without its exact counterpart;
omit that switch only for intermediate imports or migration fixtures.
Identical hashes are not automatically deduplicated.

Migration regression checks use a temporary, uniquely named fixture below a supplied
scratch directory and remove that fixture on completion:

```powershell
.\scripts\test-manage-icons.ps1 -WorkDirectory $env:TEMP
```

For future additions, use canonical paths and add corresponding provenance rows to
`catalog\migration.csv` before synchronizing formats and rebuilding. Original icon rows
use `action=move`, `role=icon`;
record the source path, current path, SHA-256, byte count, naming fields and any source
captions/slides. `original_path` must identify the upstream location, not the current
canonical path. Leave source-only fields blank when unavailable.
Do not overwrite an existing path or invent dimensions, aliases, styles, or themes.

The initial migration is explicit and resumable:

```powershell
.\scripts\manage-icons.ps1 -Mode Plan
# Review catalog\migration.csv before applying.
.\scripts\manage-icons.ps1 -Mode Apply
.\scripts\manage-icons.ps1 -Mode Build
.\scripts\manage-icons.ps1 -Mode Validate
```

`Plan` refuses to overwrite an existing mapping or populated destination structure.
`Apply` checks sources and destinations before moving files, refuses overwrites, verifies
all retained checksums, and only then removes explicitly mapped macOS metadata and
empty original folders. On interruption, rerun `Apply` with the same mapping.
Do not rerun the initial `Plan` against an already reorganized collection.
