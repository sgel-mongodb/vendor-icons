# Vendor icons

Vendor artwork organized for filename search, diagrams, presentations, and AI agents.
Original icon contents are preserved; renaming does not change artwork or usage rights.
`.gitattributes` disables automatic line-ending conversion so clones preserve the
original file bytes and recorded checksums on every platform.

## Layout

| Folder | Contents |
| --- | --- |
| `svg\` | SVG assets, grouped by vendor and then product family/category |
| `png\` | PNG assets using the same organization where available |
| `catalog\icons.json` | Searchable icon metadata, aliases, dimensions, variants, and checksums |
| `catalog\migration.csv` | Original-to-canonical mapping for every original file, including removed macOS metadata |
| `docs\vendors\` | Original vendor documentation, terms, licenses, and reference images |
| `upstream\` | Retained non-icon package files, metadata, manifests, and source artwork |
| `scripts\` | Dependency-free PowerShell 7.4+ migration, catalog, and validation tooling |

Empty vendors and missing formats have no placeholder directories. Existing vendor
categories are retained, not mapped to a speculative cross-vendor taxonomy.

## Naming

```text
<vendor>-[<family>-]<kind>[-<component>][--style-<style>][--theme-<theme>][--size-<size>][--scale-<scale>].<format>
```

Names use lowercase kebab-case. Vendor identifiers are `aws`, `microsoft`, `google`,
`mongodb`, and `capgemini`; Microsoft families are `azure` and `fabric`. MongoDB product
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

## Provenance and rights

Vendor artwork remains subject to its respective terms. This collection does not
grant a blanket license or imply that all vendors use the same license.

- Azure terms and FAQ: `docs\vendors\microsoft\azure\`.
- Fabric license and upstream README: `docs\vendors\microsoft\fabric\`.
- MongoDB extraction provenance and usage notes: `docs\vendors\mongodb\readme.md`.
- MongoDB original slide manifest: `upstream\mongodb\manifest.csv`. Its paths refer to
  the original extraction layout; use `catalog\migration.csv` to resolve current paths.
- MongoDB contact sheet: `docs\vendors\mongodb\contact-sheet.png`, not an individual icon.

MongoDB presentation-kit SVGs contain embedded PNG artwork, not reconstructed vectors.
The catalog marks these as `raster-embedded`; do not substitute the standalone brand
logo for an Atlas/product-family icon. Read the original usage guidance.

Upstream JavaScript/TypeScript files and package metadata are retained for provenance,
not offered as a working npm package after the artwork has been relocated. Original
vendor READMEs are also preserved as historical documents; their relative links and
import examples may refer to the original package layout.

## Maintenance

Run from the repository root with PowerShell 7.4 or later:

```powershell
.\scripts\manage-icons.ps1 -Mode Build
.\scripts\manage-icons.ps1 -Mode Validate
```

If local execution policy blocks unsigned scripts, invoke each command in a separate
process as `pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\manage-icons.ps1 -Mode Validate`
(substituting the desired mode). This does not change the persistent execution policy.

`Build` regenerates the catalog deterministically from the checked-in migration mapping.
`Validate` checks all retained original file hashes, catalog coverage, naming, image
metadata, absence of original vendor folders, and absence of macOS packaging debris.
Identical hashes are not automatically deduplicated.

Migration regression checks use a temporary, uniquely named fixture below a supplied
scratch directory and remove that fixture on completion:

```powershell
.\scripts\test-manage-icons.ps1 -WorkDirectory $env:TEMP
```

For future additions, use canonical paths and add corresponding provenance rows to
`catalog\migration.csv` before rebuilding. Icon rows use `action=move`, `role=icon`;
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
