# Working with vendor icons

- Search filenames under `svg\` or `png\` first. They encode vendor, optional product
  family, kind, component, and available style/theme/size variants.
- Search `catalog\icons.json` for aliases, original names, categories, and provenance.
  Use the recorded `path`; never construct a path from an assumed service name.
- Prefer SVG for scalable artwork only when `image.artwork` is `vector`.
  MongoDB presentation-kit SVGs are raster wrappers (`raster-embedded`), not true vectors.
- Preserve service/resource/category/group/UI/logo distinctions. A generic category,
  brand logo, and service icon are not interchangeable.
- Respect explicit style, theme, size, and format requests. Nominal size suffixes are
  vendor variant labels; actual dimensions are in `image.width` and `image.height`.
- Corresponding formats can share a name, but not every icon has both formats.
- Do not silently modernize historical product names or infer product equivalence.
- Read vendor usage notes under `docs\vendors\`; no repository-wide artwork license
  supersedes vendor terms.
- Red Hat artwork is CC BY 4.0, not the upstream software's MIT license. Preserve its
  attribution and pinned `source` links. Standard resources are generic brand icons,
  not substitutes for OpenShift, RHEL, Ansible, or other product-technology icons.
- Keep icon bytes unchanged unless an artwork edit is explicitly requested. Never
  deduplicate, rasterize, optimize, or reconstruct artwork as part of routine organization.
- Preserve original files and provenance in `catalog\migration.csv`. Archived source
  documents and manifests retain their original text and may reference old paths;
  resolve those through the migration mapping.
- After an approved asset/mapping change, run `.\scripts\manage-icons.ps1 -Mode Build`
  and `.\scripts\manage-icons.ps1 -Mode Validate` with PowerShell 7.4+.
- Do not commit macOS metadata, OS thumbnails, or installed dependencies.
