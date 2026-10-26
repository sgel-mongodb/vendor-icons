#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ArchivePath,
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$revision = 'd4f3eaa75084faa0025a3f82cde4d4796b7e056e'
$archiveHash = '9d3b73ba67658966d04fd36de2da3f88697cc3b93450d40821e512e31bd63b1c'
$sourceRepository = 'https://github.com/RedHat-UX/red-hat-icons'
$mappingPath = Join-Path $Root 'catalog\migration.csv'
$prefix = "red-hat-icons-$revision/"

if ((Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $archiveHash) {
    throw 'Archive checksum does not match the pinned official Red Hat source.'
}
if (-not (Test-Path -LiteralPath $mappingPath)) { throw 'An existing migration mapping is required.' }

$sourceFields = @('source_url', 'source_revision', 'source_license', 'source_attribution')
$rows = [Collections.Generic.List[object]]::new()
$byPath = @{}
$byOriginal = @{}
foreach ($row in Import-Csv -LiteralPath $mappingPath) {
    foreach ($field in $sourceFields) {
        if (-not $row.PSObject.Properties[$field]) { $row | Add-Member -NotePropertyName $field -NotePropertyValue '' }
    }
    if ($row.path) {
        if ($byPath.ContainsKey($row.path)) { throw "Duplicate mapped path: $($row.path)" }
        $byPath[$row.path] = $row
    }
    if ($byOriginal.ContainsKey($row.original_path)) { throw "Duplicate original path: $($row.original_path)" }
    $byOriginal[$row.original_path] = $row
    $rows.Add($row)
}
if (-not $rows.Count) { throw 'The existing migration mapping is empty.' }

$aliases = @{
    'ai-ml' = 'Artificial intelligence and machine learning'
    'api' = 'Application Programming Interface'
    'kubernetes-pod' = 'Kubernetes pod; k8s pod'
    'mcp-server' = 'Model Context Protocol server'
}
$notices = @{
    'LICENSE_ICONS.md' = 'docs\vendors\redhat\red-hat-icons\license-icons.md'
    'LICENSE.md' = 'docs\vendors\redhat\red-hat-icons\license-software.md'
    'README.md' = 'docs\vendors\redhat\red-hat-icons\upstream-readme.md'
    'package.json' = 'upstream\redhat\red-hat-icons\package.json'
}
$imports = [Collections.Generic.List[object]]::new()
$counts = @{ standard = 0; ui = 0; microns = 0 }
$archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ArchivePath).Path)
try {
    foreach ($entry in $archive.Entries) {
        if (-not $entry.FullName.StartsWith($prefix, [StringComparison]::Ordinal)) {
            throw "Unexpected archive entry: $($entry.FullName)"
        }
        $sourcePath = $entry.FullName.Substring($prefix.Length)
        $set = ''
        $component = ''
        $kind = ''
        $caption = ''
        $role = 'documentation'
        if ($sourcePath -cmatch '^src/(standard|ui|microns)/([a-z0-9][a-z0-9-]*)\.svg$') {
            $set = $Matches[1]
            $component = $Matches[2]
            $kind = if ($set -eq 'standard') { 'resource' } else { 'ui' }
            $destination = "svg\redhat\$set\redhat-$kind-$component--style-$set.svg"
            $role = 'icon'
            $counts[$set]++
            if ($aliases.ContainsKey($component)) { $caption = $aliases[$component] }
        } elseif ($notices.ContainsKey($sourcePath)) {
            $destination = $notices[$sourcePath]
            if ($sourcePath -eq 'package.json') { $role = 'upstream' }
        } else { continue }

        $stream = $entry.Open()
        $buffer = [IO.MemoryStream]::new()
        try {
            $stream.CopyTo($buffer)
            $bytes = $buffer.ToArray()
        } finally {
            $stream.Dispose()
            $buffer.Dispose()
        }
        $hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
        $original = "Redhat\red-hat-icons\$revision\" + $sourcePath.Replace('/', '\')
        $values = [ordered]@{}
        foreach ($field in $rows[0].PSObject.Properties.Name) { $values[$field] = '' }
        $values.action = 'move'
        $values.role = $role
        $values.original_path = $original
        $values.path = $destination
        $values.sha256 = $hash
        $values.bytes = [string]$bytes.Length
        $values.vendor = 'redhat'
        $values.category = $set
        $values.kind = $kind
        $values.component = $component
        $values.style = $set
        $values.captions = $caption
        $values.source_url = "$sourceRepository/blob/$revision/$sourcePath"
        $values.source_revision = $revision
        $values.source_license = if ($role -eq 'icon') { 'CC-BY-4.0' } else { '' }
        $values.source_attribution = 'Red Hat, Inc.'
        $newRow = [pscustomobject]$values
        if ($byOriginal.ContainsKey($original) -and $byOriginal[$original].path -ne $destination) {
            throw "Original source already mapped elsewhere: $original"
        }
        if ($byPath.ContainsKey($destination)) {
            foreach ($field in $values.Keys) {
                if ([string]$byPath[$destination].$field -cne [string]$values[$field]) {
                    throw "Existing provenance conflicts with the import: $destination [$field]"
                }
            }
        } else {
            $byPath[$destination] = $newRow
            $byOriginal[$original] = $newRow
            $rows.Add($newRow)
        }
        $fullPath = [IO.Path]::GetFullPath((Join-Path $Root $destination))
        if (-not $fullPath.StartsWith($Root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw "Destination escapes the repository: $destination"
        }
        if (Test-Path -LiteralPath $fullPath) {
            if ((Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $hash) {
                throw "Refusing to overwrite different content: $destination"
            }
        }
        $imports.Add([pscustomobject]@{ Path = $fullPath; Bytes = $bytes; Role = $role })
    }
} finally { $archive.Dispose() }

if ($counts.standard -ne 555 -or $counts.ui -ne 603 -or $counts.microns -ne 35 -or $imports.Count -ne 1197) {
    throw 'Pinned archive is missing expected icons or license/provenance files.'
}
foreach ($item in $imports) {
    if (-not (Test-Path -LiteralPath $item.Path)) {
        [IO.Directory]::CreateDirectory((Split-Path $item.Path -Parent)) | Out-Null
        $stream = [IO.File]::Open($item.Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
        try { $stream.Write($item.Bytes, 0, $item.Bytes.Length) } finally { $stream.Dispose() }
    }
}
$temporary = $mappingPath + '.' + [guid]::NewGuid().ToString('N') + '.pending'
try {
    $rows | Sort-Object original_path | Export-Csv -LiteralPath $temporary -NoTypeInformation -Encoding utf8
    [IO.File]::Move($temporary, $mappingPath, $true)
} finally {
    if (Test-Path -LiteralPath $temporary) { [IO.File]::Delete($temporary) }
}
Write-Host 'Imported 1,193 Red Hat SVGs and 4 upstream license/provenance files without altering their contents.'
