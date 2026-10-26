[CmdletBinding()]
param(
    [ValidateSet('Plan', 'Apply', 'Build', 'Validate')]
    [string]$Mode = 'Validate',
    [string]$Root = (Split-Path $PSScriptRoot -Parent),
    [switch]$RequirePairs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$catalogDirectory = Join-Path $Root 'catalog'
$mappingPath = Join-Path $catalogDirectory 'migration.csv'
$catalogPath = Join-Path $catalogDirectory 'icons.json'
$vendorRoots = @('AWS', 'Capgemini', 'Google', 'Microsoft', 'MongoDB', 'Redhat')

function Get-Slug([string]$Text) {
    $Text = [regex]::Replace($Text, '(?<![a-zA-Z])[A-Z]{2,}s(?![a-zA-Z])', {
        param($match)
        $match.Value.ToLowerInvariant()
    })
    $value = $Text -creplace '([A-Z]+)([A-Z][a-z])', '$1-$2'
    $value = $value -creplace '([a-z0-9])([A-Z])', '$1-$2'
    $value = ($value.ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-')
    $value = $value -replace '\bwork-spaces\b', 'workspaces' -replace '\bbig-query\b', 'bigquery' -replace '\balloy-db\b', 'alloydb'
    if (-not $value) { throw "Cannot create a name from '$Text'." }
    return $value
}

function Get-RelativePath([string]$Path) {
    return [IO.Path]::GetRelativePath($Root, $Path)
}

function Get-LocalPath([string]$Relative) {
    if ([IO.Path]::IsPathRooted($Relative)) { throw "Expected a relative path: $Relative" }
    $full = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if (-not $full.StartsWith($Root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes the repository: $Relative"
    }
    return $full
}

function Test-Metadata([string]$Relative) {
    return @($Relative -split '\\' | Where-Object {
        $_ -eq '__MACOSX' -or $_ -eq '.DS_Store' -or $_.StartsWith('._')
    }).Count -gt 0
}

function Get-AssetName([string]$Relative) {
    $parts = $Relative -split '\\'
    $stem = [IO.Path]::GetFileNameWithoutExtension($Relative)
    $format = [IO.Path]::GetExtension($Relative).TrimStart('.').ToLowerInvariant()
    $vendor = $parts[0].ToLowerInvariant()
    $family = ''
    $category = ''
    $kind = ''
    $component = ''
    $style = ''
    $theme = ''
    $size = ''
    $scale = ''
    $sourceId = ''
    $colorSpace = ''

    switch ($vendor) {
        'aws' {
            if ($stem -notmatch '^(.*?)_(16|32|48|64)(?:@(\d+x))?(?:_(Dark|Light))?$') {
                throw "Unrecognized AWS variant: $Relative"
            }
            $component = $Matches[1]
            $size = $Matches[2]
            if ($Matches.ContainsKey(3)) { $scale = $Matches[3] }
            if ($Matches.ContainsKey(4)) { $theme = $Matches[4].ToLowerInvariant() }
            switch -Wildcard ($parts[1]) {
                'Architecture-Service-*' {
                    $kind = 'service'
                    $category = Get-Slug ($parts[2] -replace '^Arch_', '')
                    $component = $component -replace '^Arch_', ''
                }
                'Resource-*' {
                    $kind = 'resource'
                    $category = Get-Slug ($parts[2] -replace '^Res_', '')
                    $component = $component -replace '^Res_', '' -replace '^AWS[-_]', ''
                }
                'Category-*' {
                    $kind = 'category'
                    $component = $component -replace '^Arch-Category_', ''
                    $category = Get-Slug $component
                }
                'Architecture-Group-*' {
                    $kind = 'group'
                    $category = 'groups'
                    $component = $component -replace '^AWS-', ''
                }
                default { throw "Unrecognized AWS collection: $Relative" }
            }
        }
        'microsoft' {
            if ($parts[1] -eq 'Fabric Icons') {
                $family = 'fabric'
                $kind = 'ui'
                if ($stem -notmatch '^(.+)_(\d+)_(.+)$') {
                    throw "Unrecognized Fabric variant: $Relative"
                }
                $component = $Matches[1]
                $size = $Matches[2]
                $style = Get-Slug $Matches[3]
            } elseif ($parts[1] -eq 'Azure_Public_Service_Icons') {
                $family = 'azure'
                $kind = 'service'
                $category = Get-Slug $parts[3]
                if ($stem -notmatch '^(\d+)\s*-icon-service-(.+)$') {
                    throw "Unrecognized Azure name: $Relative"
                }
                $sourceId = $Matches[1]
                $component = $Matches[2] -replace '^Azure-', ''
            } else { throw "Unrecognized Microsoft collection: $Relative" }
        }
        'google' {
            $kind = if ($parts[1] -eq 'Category Icons') { 'category' } else { 'service' }
            $category = if ($kind -eq 'category') { 'categories' } else { 'services' }
            $component = $parts[2]
            if ($stem -notmatch '-(\d+)-(color)(-rgb)?$') {
                throw "Unrecognized Google variant: $Relative"
            }
            $size = $Matches[1]
            $style = $Matches[2]
            if ($Matches[3]) { $colorSpace = 'rgb' }
        }
        'mongodb' {
            if ($parts.Length -eq 2) {
                $kind = 'logo'
                $component = ''
            } else {
                $category = Get-Slug $parts[2]
                if ($category -eq 'contact-sheet.png') {
                    throw "Contact sheets must not be treated as icons: $Relative"
                }
                $kind = 'resource'
                $component = $stem
                if ($category -in @('atlas', 'realm', 'enterprise-advanced', 'community-edition')) {
                    $family = $category
                    $component = $component -replace ('^' + [regex]::Escape($family) + '[-_ ]'), ''
                } elseif ($category -ne 'mongo-db') {
                    $component = "$category-$component"
                }
                if ($category -eq 'mongo-db') { $category = 'mongodb' }
            }
        }
        'capgemini' {
            $kind = 'logo'
            $component = ''
            if ($stem -ne 'Capgemini_201x_logo') { throw "Unrecognized Capgemini logo: $Relative" }
            $style = '201x'
        }
        default { throw "Unrecognized vendor: $Relative" }
    }

    # Vendor spellings and product acronyms are identifiers, not camel-case words.
    $component = if ($component) { Get-Slug $component } else { '' }
    $component = $component -replace '\bmongo-db\b', 'mongodb' -replace '\bio-t\b', 'iot'
    $category = $category -replace '\bio-t\b', 'iot'
    $nameParts = @($vendor, $family, $kind, $component) | Where-Object { $_ }
    $name = $nameParts -join '-'
    if ($style) { $name += "--style-$style" }
    if ($theme) { $name += "--theme-$theme" }
    if ($size) { $name += "--size-$size" }
    if ($scale) { $name += "--scale-$scale" }
    $directories = @($format, $vendor, $family) | Where-Object { $_ }
    if ($category -and $category -ne $family) { $directories += $category }
    return [pscustomobject]@{
        Name = $name; Vendor = $vendor; Family = $family; Category = $category
        Kind = $kind; Component = $component; Style = $style; Theme = $theme
        Size = $size; Scale = $scale; SourceId = $sourceId; ColorSpace = $colorSpace
        Destination = (($directories + "$name.$format") -join '\')
    }
}

function New-Plan {
    if (Test-Path -LiteralPath $mappingPath) { throw "Migration mapping already exists: $mappingPath" }
    foreach ($directory in @('svg', 'png', 'docs', 'upstream')) {
        if (Test-Path -LiteralPath (Join-Path $Root $directory)) {
            throw "Destination already exists; refusing to plan over existing content: $directory"
        }
    }
    $mongoManifest = @{}
    $manifestPath = Join-Path $Root 'MongoDB\MongoDB_Presentation_Icon_Kit\manifest.csv'
    foreach ($entry in Import-Csv -LiteralPath $manifestPath) {
        foreach ($format in @('png', 'svg')) {
            $key = 'MongoDB\MongoDB_Presentation_Icon_Kit\' + $entry.$format.Replace('/', '\')
            if ($mongoManifest.ContainsKey($key)) {
                $mongoManifest[$key].Captions += $entry.caption
                $mongoManifest[$key].Slides += $entry.slide
            } else {
                $mongoManifest[$key] = @{ Captions = @($entry.caption); Slides = @($entry.slide) }
            }
        }
    }
    $rows = [Collections.Generic.List[object]]::new()
    foreach ($vendor in $vendorRoots) {
        $sourceRoot = Join-Path $Root $vendor
        if (-not (Test-Path -LiteralPath $sourceRoot)) { continue }
        foreach ($file in Get-ChildItem -LiteralPath $sourceRoot -File -Recurse -Force) {
            $relative = Get-RelativePath $file.FullName
            $action = 'move'
            $asset = $null
            $destination = ''
            $role = 'upstream'
            if (Test-Metadata $relative) {
                $action = 'remove-metadata'
                $role = 'metadata'
            } elseif ($file.Name -eq 'contact_sheet.png') {
                $destination = 'docs\vendors\mongodb\contact-sheet.png'
                $role = 'reference'
            } elseif ($file.Extension.ToLowerInvariant() -in @('.svg', '.png')) {
                $asset = Get-AssetName $relative
                $destination = $asset.Destination
                $role = 'icon'
            } else {
                $parts = $relative -split '\\'
                $vendorName = $vendor.ToLowerInvariant()
                $family = ''
                $remaining = @($parts | Select-Object -Skip 1)
                if ($vendor -eq 'Microsoft') {
                    $family = if ($parts[1] -eq 'Fabric Icons') { 'fabric' } else { 'azure' }
                    $remaining = @($parts | Select-Object -Skip 2)
                } elseif ($vendor -eq 'MongoDB') {
                    $remaining = @($parts | Select-Object -Skip 2)
                }
                if ($file.Extension -in @('.md', '.pdf') -or $file.Name -eq 'LICENSE') {
                    $role = 'documentation'
                    $base = Get-Slug $file.BaseName
                    $remaining = @($remaining | Select-Object -SkipLast 1) + ($base + $file.Extension.ToLowerInvariant())
                    $destination = (@('docs', 'vendors', $vendorName, $family) + $remaining |
                        Where-Object { $_ }) -join '\'
                } else {
                    $destination = (@('upstream', $vendorName, $family) + $remaining |
                        Where-Object { $_ }) -join '\'
                }
            }
            $row = [ordered]@{
                action = $action; role = $role; original_path = $relative; path = $destination
                sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
                bytes = $file.Length; vendor = ''; family = ''; category = ''; kind = ''
                component = ''; style = ''; theme = ''; size = ''; scale = ''; source_id = ''; color_space = ''
                captions = ''; source_slides = ''
            }
            if ($null -ne $asset) {
                foreach ($field in @('vendor', 'family', 'category', 'kind', 'component', 'style', 'theme', 'size', 'scale')) {
                    $row[$field] = $asset.$field
                }
                $row.source_id = $asset.SourceId
                $row.color_space = $asset.ColorSpace
                if ($mongoManifest.ContainsKey($relative)) {
                    $row.captions = ($mongoManifest[$relative].Captions | Sort-Object -Unique) -join '; '
                    $row.source_slides = ($mongoManifest[$relative].Slides | Sort-Object -Unique) -join '; '
                }
            }
            $rows.Add([pscustomobject]$row)
        }
    }
    # Preserve distinct Azure source IDs when names normalize to the same destination.
    foreach ($group in $rows | Where-Object action -eq 'move' | Group-Object path | Where-Object Count -gt 1) {
        foreach ($row in $group.Group) {
            if (-not $row.source_id) { throw "Unresolved naming collision: $($group.Name)" }
            $row.path = $row.path -replace '(\.[^.]+)$', "--source-id-$($row.source_id)`$1"
        }
    }
    $duplicates = @($rows | Where-Object action -eq 'move' | Group-Object path | Where-Object Count -gt 1)
    if ($duplicates.Count) { throw "Duplicate destinations: $($duplicates.Name -join ', ')" }
    [IO.Directory]::CreateDirectory($catalogDirectory) | Out-Null
    $rows | Sort-Object original_path | Export-Csv -LiteralPath $mappingPath -NoTypeInformation -Encoding utf8
    $rows | Group-Object action, role | Select-Object Name, Count | Format-Table -AutoSize
    Write-Host "Plan saved to $mappingPath. No source files changed."
}

function Get-Mapping {
    if (-not (Test-Path -LiteralPath $mappingPath)) { throw 'Run Plan first.' }
    return @(Import-Csv -LiteralPath $mappingPath)
}

function Assert-Hash([string]$Path, [string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing file: $Path" }
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $Expected) { throw "Checksum mismatch: $Path" }
}

function Invoke-Migration {
    $rows = Get-Mapping
    $retained = @($rows | Where-Object action -eq 'move')
    if (-not $retained.Count) { throw 'The mapping contains no retained files.' }
    $destinations = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($row in $retained) {
        if (-not $destinations.Add($row.path)) { throw "Duplicate destination: $($row.path)" }
        $source = Get-LocalPath $row.original_path
        $destination = Get-LocalPath $row.path
        if (Test-Path -LiteralPath $source) {
            Assert-Hash $source $row.sha256
            if (Test-Path -LiteralPath $destination) { throw "Destination already exists: $destination" }
        } else {
            Assert-Hash $destination $row.sha256
        }
    }
    foreach ($row in $retained) {
        $source = Get-LocalPath $row.original_path
        $destination = Get-LocalPath $row.path
        if (Test-Path -LiteralPath $source) {
            [IO.Directory]::CreateDirectory((Split-Path $destination -Parent)) | Out-Null
            [IO.File]::Move($source, $destination)
        }
    }
    foreach ($row in $retained) { Assert-Hash (Get-LocalPath $row.path) $row.sha256 }
    foreach ($row in $rows | Where-Object action -eq 'remove-metadata') {
        if (-not (Test-Metadata $row.original_path)) { throw "Not macOS metadata: $($row.original_path)" }
        $source = Get-LocalPath $row.original_path
        if (Test-Path -LiteralPath $source) {
            Assert-Hash $source $row.sha256
            Remove-Item -LiteralPath $source -Force
        }
    }
    foreach ($vendor in $vendorRoots) {
        $sourceRoot = Join-Path $Root $vendor
        if (-not (Test-Path -LiteralPath $sourceRoot)) { continue }
        $directories = @(Get-ChildItem -LiteralPath $sourceRoot -Directory -Recurse -Force |
            Sort-Object { $_.FullName.Length } -Descending)
        foreach ($directory in $directories) {
            if (-not @(Get-ChildItem -LiteralPath $directory.FullName -Force).Count) {
                [IO.Directory]::Delete($directory.FullName)
            }
        }
        if (-not @(Get-ChildItem -LiteralPath $sourceRoot -Force).Count) {
            [IO.Directory]::Delete($sourceRoot)
        }
    }
    Write-Host "Migration complete: $($retained.Count) files preserved."
}

function Get-ImageMetadata([string]$Path) {
    $format = [IO.Path]::GetExtension($Path).TrimStart('.')
    $width = $null
    $height = $null
    $viewBox = $null
    $artwork = 'raster'
    if ($format -eq 'png') {
        $stream = [IO.File]::OpenRead($Path)
        try {
            $header = [byte[]]::new(24)
            $stream.ReadExactly($header, 0, 24)
            if ([Convert]::ToHexString($header[0..7]) -ne '89504E470D0A1A0A' -or
                [Text.Encoding]::ASCII.GetString($header, 12, 4) -ne 'IHDR') {
                throw "Invalid PNG header: $Path"
            }
            $widthBytes = [byte[]]$header[16..19]
            $heightBytes = [byte[]]$header[20..23]
            if ([BitConverter]::IsLittleEndian) {
                [Array]::Reverse($widthBytes)
                [Array]::Reverse($heightBytes)
            }
            $width = [BitConverter]::ToUInt32($widthBytes, 0)
            $height = [BitConverter]::ToUInt32($heightBytes, 0)
        } finally { $stream.Dispose() }
    } else {
        $settings = [Xml.XmlReaderSettings]::new()
        $settings.DtdProcessing = [Xml.DtdProcessing]::Ignore
        $settings.XmlResolver = $null
        $reader = [Xml.XmlReader]::Create($Path, $settings)
        try {
            $document = [Xml.XmlDocument]::new()
            $document.XmlResolver = $null
            $document.Load($reader)
        } finally { $reader.Dispose() }
        $svg = $document.DocumentElement
        if ($svg.LocalName -ne 'svg') { throw "Not an SVG document: $Path" }
        $width = $svg.GetAttribute('width')
        $height = $svg.GetAttribute('height')
        $viewBox = $svg.GetAttribute('viewBox')
        $images = $document.SelectNodes('//*[local-name()="image"]').Count
        $shapes = $document.SelectNodes('//*[local-name()="path" or local-name()="rect" or local-name()="circle" or local-name()="ellipse" or local-name()="polygon" or local-name()="polyline" or local-name()="line" or local-name()="text" or local-name()="use"]').Count
        $artwork = if ($images -and $shapes) { 'mixed' } elseif ($images) { 'raster-embedded' } else { 'vector' }
    }
    return [ordered]@{ width = $width; height = $height; view_box = $viewBox; artwork = $artwork }
}

function New-Catalog {
    $icons = [Collections.Generic.List[object]]::new()
    foreach ($row in Get-Mapping | Where-Object role -eq 'icon' | Sort-Object path) {
        $path = Get-LocalPath $row.path
        Assert-Hash $path $row.sha256
        $name = [IO.Path]::GetFileNameWithoutExtension($path)
        $format = [IO.Path]::GetExtension($path).TrimStart('.')
        $aliases = @($row.component.Replace('-', ' '), [IO.Path]::GetFileNameWithoutExtension($row.original_path))
        if ($row.captions) { $aliases += $row.captions -split '; ' }
        if ($row.vendor -eq 'google' -and $row.component -eq 'gke') { $aliases += 'Google Kubernetes Engine' }
        if ($row.vendor -eq 'google' -and $row.component -eq 'security-operations') { $aliases += 'SecOps' }
        if ($row.vendor -eq 'aws' -and $row.component -eq 'amazon-ec2') { $aliases += 'Elastic Compute Cloud' }
        if ($row.vendor -eq 'aws' -and $row.component -eq 'amazon-s3') { $aliases += 'Simple Storage Service' }
        $icon = [ordered]@{
            name = $name; format = $format; path = $row.path
            vendor = $row.vendor; family = $row.family; category = $row.category; kind = $row.kind
            component = $row.component; aliases = @($aliases | Where-Object { $_ } | Sort-Object -Unique)
            variants = [ordered]@{ style = $row.style; theme = $row.theme; size = $row.size; scale = $row.scale; color_space = $row.color_space }
            image = Get-ImageMetadata $path
            original_path = $row.original_path; original_filename = [IO.Path]::GetFileName($row.original_path)
            source_id = $row.source_id; source_slides = $row.source_slides
            bytes = [long]$row.bytes; sha256 = $row.sha256
        }
        if ($row.PSObject.Properties['source_url'] -and $row.source_url) {
            $icon.source = [ordered]@{
                url = $row.source_url; revision = $row.source_revision
                license = $row.source_license; attribution = $row.source_attribution
            }
        }
        if ($row.action -eq 'generate') {
            $icon.derivation = [ordered]@{
                method = $row.generation_method; from = $row.derived_from
                source_sha256 = $row.derived_from_sha256; renderer = $row.renderer
                longest_edge = $row.render_longest_edge
            }
        }
        $icons.Add($icon)
    }
    $catalog = [ordered]@{ schema_version = 1; asset_count = $icons.Count; icons = @($icons.ToArray()) }
    $catalog | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $catalogPath -Encoding utf8
    Write-Host "Catalog generated: $($icons.Count) icons."
}

function Test-Repository {
    $rows = Get-Mapping
    $retained = @($rows | Where-Object action -in @('move', 'generate'))
    foreach ($row in $retained) {
        Assert-Hash (Get-LocalPath $row.path) $row.sha256
        if ($row.action -eq 'move' -and (Test-Path -LiteralPath (Get-LocalPath $row.original_path))) {
            throw "Original file still exists: $($row.original_path)"
        }
    }
    foreach ($vendor in $vendorRoots) {
        if (Test-Path -LiteralPath (Join-Path $Root $vendor)) { throw "Original vendor folder remains: $vendor" }
    }
    $catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
    $iconRows = @($rows | Where-Object role -eq 'icon')
    if ($catalog.asset_count -ne $iconRows.Count -or @($catalog.icons).Count -ne $iconRows.Count) {
        throw 'Catalog count does not match the migration mapping.'
    }
    $expected = @{}
    foreach ($row in $iconRows) {
        if ($expected.ContainsKey($row.path)) { throw "Duplicate mapped icon: $($row.path)" }
        $expected[$row.path] = $row
    }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($icon in $catalog.icons) {
        if (-not $seen.Add($icon.path) -or -not $expected.ContainsKey($icon.path)) {
            throw "Duplicate or unexpected catalog path: $($icon.path)"
        }
        if ($icon.sha256 -ne $expected[$icon.path].sha256 -or
            $icon.original_path -ne $expected[$icon.path].original_path) {
            throw "Catalog provenance mismatch: $($icon.path)"
        }
        $row = $expected[$icon.path]
        if ($row.PSObject.Properties['source_url'] -and $row.source_url) {
            if (-not $icon.PSObject.Properties['source']) { throw "Missing source attribution: $($icon.path)" }
            foreach ($field in @('url', 'revision', 'license', 'attribution')) {
                if ($icon.source.$field -cne $row.("source_$field")) {
                    throw "Catalog source mismatch: $($icon.path) [$field]"
                }
            }
            if ($row.action -eq 'generate') {
                if (-not $icon.PSObject.Properties['derivation']) { throw "Missing derivation: $($icon.path)" }
                $fields = @{
                    method = 'generation_method'; from = 'derived_from'; source_sha256 = 'derived_from_sha256'
                    renderer = 'renderer'; longest_edge = 'render_longest_edge'
                }
                foreach ($field in $fields.Keys) {
                    if ($icon.derivation.$field -cne $row.($fields[$field])) {
                        throw "Catalog derivation mismatch: $($icon.path) [$field]"
                    }
                }
                if ($row.derived_from -eq $row.path -or -not $expected.ContainsKey($row.derived_from) -or
                    $expected[$row.derived_from].sha256 -cne $row.derived_from_sha256) {
                    throw "Invalid derivation source: $($icon.path)"
                }
                Assert-Hash (Get-LocalPath $row.derived_from) $row.derived_from_sha256
                switch ($row.generation_method) {
                    'svg-to-png' {
                        if ($icon.format -ne 'png' -or $row.derived_from -notlike 'svg\*.svg' -or
                            -not $row.renderer -or [int]$row.render_longest_edge -le 0 -or
                            [Math]::Max([double]$icon.image.width, [double]$icon.image.height) -ne [int]$row.render_longest_edge) {
                            throw "Invalid SVG-to-PNG output: $($icon.path)"
                        }
                    }
                    'source-svg-copy' {
                        if ($icon.format -ne 'svg' -or $row.derived_from -notlike 'svg\*.svg' -or
                            $row.sha256 -cne $row.derived_from_sha256) {
                            throw "Copied vector differs from its source: $($icon.path)"
                        }
                    }
                    default { throw "Unsupported generation method: $($row.generation_method)" }
                }
            }
        }
        if ($icon.path -cnotmatch '^(svg|png)\\[a-z0-9\\-]+\.(svg|png)$' -or
            $icon.path -cnotmatch ('^' + $icon.format + '\\') -or
            $icon.path -cnotmatch ('\.' + $icon.format + '$') -or
            [IO.Path]::GetFileNameWithoutExtension($icon.path) -cne $icon.name) {
            throw "Noncanonical icon path: $($icon.path)"
        }
        $metadata = Get-ImageMetadata (Get-LocalPath $icon.path)
        foreach ($field in @('width', 'height', 'view_box', 'artwork')) {
            if ([string]$metadata[$field] -cne [string]$icon.image.$field) {
                throw "Catalog image metadata mismatch: $($icon.path) [$field]"
            }
        }
        if ($icon.format -eq 'svg' -and $icon.original_path -like 'MongoDB\MongoDB_Presentation_Icon_Kit\*' -and
            $icon.image.artwork -ne 'raster-embedded') {
            throw "MongoDB raster wrapper incorrectly classified: $($icon.path)"
        }
        if ($RequirePairs) {
            $counterpart = if ($icon.format -eq 'svg') {
                $icon.path -replace '^svg\\', 'png\' -replace '\.svg$', '.png'
            } else {
                $icon.path -replace '^png\\', 'svg\' -replace '\.png$', '.svg'
            }
            if (-not $expected.ContainsKey($counterpart)) { throw "Missing format counterpart: $counterpart" }
        }
    }
    foreach ($format in @('svg', 'png')) {
        foreach ($file in Get-ChildItem -LiteralPath (Join-Path $Root $format) -File -Recurse -Force) {
            if (-not $expected.ContainsKey((Get-RelativePath $file.FullName))) {
                throw "Uncataloged asset: $($file.FullName)"
            }
        }
    }
    $debris = @(Get-ChildItem -LiteralPath $Root -File -Recurse -Force |
        Where-Object { Test-Metadata (Get-RelativePath $_.FullName) })
    if ($debris.Count) { throw "macOS metadata remains: $($debris.Count) files." }
    Write-Host "Validated $($iconRows.Count) icons and $($retained.Count - $iconRows.Count) ancillary files; all original checksums preserved."
}

switch ($Mode) {
    'Plan' { New-Plan }
    'Apply' { Invoke-Migration }
    'Build' { New-Catalog }
    'Validate' { Test-Repository }
}
