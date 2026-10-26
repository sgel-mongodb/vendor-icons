#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RendererPath,
    [string]$Root = (Split-Path $PSScriptRoot -Parent)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)
$renderer = (Resolve-Path -LiteralPath $RendererPath).Path
$rendererHash = '266b45d69cd80aafbd7ff2b6424a6a6c2e476888a535a4ce38d5a055bed95624'
if ((Get-FileHash -LiteralPath $renderer).Hash.ToLowerInvariant() -ne $rendererHash) {
    throw 'Renderer checksum does not match the pinned official resvg 0.49.0 Windows x64 executable.'
}
$version = & $renderer --version
if ($LASTEXITCODE -ne 0 -or $version -ne '0.49.0') { throw 'Unexpected resvg version.' }

function Get-LocalPath([string]$Relative) {
    if ([IO.Path]::IsPathRooted($Relative)) { throw "Expected a relative path: $Relative" }
    $full = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if (-not $full.StartsWith($Root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path escapes the repository: $Relative"
    }
    return $full
}

$mappingPath = Join-Path $Root 'catalog\migration.csv'
$rows = [Collections.Generic.List[object]]::new()
$byPath = @{}
$generationFields = @('generation_method', 'derived_from', 'derived_from_sha256', 'renderer', 'render_longest_edge')
foreach ($row in Import-Csv -LiteralPath $mappingPath) {
    foreach ($field in $generationFields) {
        if (-not $row.PSObject.Properties[$field]) { $row | Add-Member -NotePropertyName $field -NotePropertyValue '' }
    }
    if ($row.path) {
        if ($byPath.ContainsKey($row.path)) { throw "Duplicate mapped destination: $($row.path)" }
        $byPath[$row.path] = $row
    }
    $rows.Add($row)
}
$icons = @($rows | Where-Object role -eq 'icon')
if (-not $icons.Count) { throw 'No cataloged icons were found.' }
foreach ($row in $icons) {
    $full = Get-LocalPath $row.path
    if ((Get-FileHash -LiteralPath $full).Hash.ToLowerInvariant() -ne $row.sha256) {
        throw "Source checksum mismatch: $($row.path)"
    }
}

$jobs = [Collections.Generic.List[object]]::new()
foreach ($row in $icons | Sort-Object path) {
    $format = [IO.Path]::GetExtension($row.path)
    if ($format -eq '.svg') {
        $target = $row.path -replace '^svg\\', 'png\' -replace '\.svg$', '.png'
        $method = 'svg-to-png'
        $source = $row
    } elseif ($format -eq '.png') {
        $target = $row.path -replace '^png\\', 'svg\' -replace '\.png$', '.svg'
        $method = 'source-svg-copy'
        $source = $null
    } else { throw "Unsupported icon format: $($row.path)" }
    if ($byPath.ContainsKey($target)) { continue }
    if ($method -eq 'source-svg-copy') {
        $baseVector = $target -replace '--scale-5x(?=\.svg$)', ''
        if ($baseVector -eq $target -or -not $byPath.ContainsKey($baseVector) -or
            $byPath[$baseVector].role -ne 'icon') {
            throw "No existing vector source for PNG-only asset: $($row.path). Tracing and raster wrappers are not permitted."
        }
        $source = $byPath[$baseVector]
    }
    $jobs.Add([pscustomobject]@{
        Row = $row; Source = $source; SourcePath = Get-LocalPath $source.path
        Target = $target; Destination = Get-LocalPath $target; Method = $method
        Temporary = ''; Hash = ''; Bytes = 0
    })
}
if (-not $jobs.Count) {
    Write-Host 'Every cataloged icon already has an SVG and PNG counterpart. No files changed.'
    return
}

$staging = Join-Path ([IO.Path]::GetTempPath()) ('vendor-icons-format-sync-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($staging) | Out-Null
try {
    $index = 0
    foreach ($job in $jobs) {
        $job.Temporary = Join-Path $staging (([string]$index++) + [IO.Path]::GetExtension($job.Target))
    }
    $rendered = @($jobs | ForEach-Object -Parallel {
        $ErrorActionPreference = 'Stop'
        $job = $_
        if ($job.Method -eq 'source-svg-copy') {
            [IO.File]::Copy($job.SourcePath, $job.Temporary, $false)
        } else {
            $start = [Diagnostics.ProcessStartInfo]::new()
            $start.FileName = $using:renderer
            $start.UseShellExecute = $false
            $start.CreateNoWindow = $true
            $start.RedirectStandardOutput = $true
            $start.RedirectStandardError = $true
            foreach ($argument in @('--width', '512', '--height', '512', $job.SourcePath, $job.Temporary)) {
                $start.ArgumentList.Add($argument)
            }
            $process = [Diagnostics.Process]::new()
            $process.StartInfo = $start
            try {
                if (-not $process.Start()) { throw "Cannot start renderer for $($job.Source.path)." }
                $stdout = $process.StandardOutput.ReadToEndAsync()
                $stderr = $process.StandardError.ReadToEndAsync()
                $process.WaitForExit()
                $diagnostics = ($stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()).Trim()
                if ($process.ExitCode -ne 0 -or $diagnostics) {
                    throw "Rendering failed for $($job.Source.path) (exit $($process.ExitCode)): $diagnostics"
                }
            } finally { $process.Dispose() }
            $stream = [IO.File]::OpenRead($job.Temporary)
            try {
                $header = [byte[]]::new(26)
                $stream.ReadExactly($header, 0, 26)
            } finally { $stream.Dispose() }
            if ([Convert]::ToHexString($header[0..7]) -ne '89504E470D0A1A0A' -or
                [Text.Encoding]::ASCII.GetString($header, 12, 4) -ne 'IHDR') {
                throw "Renderer produced an invalid PNG for $($job.Source.path)."
            }
            $width = [Convert]::ToUInt32([Convert]::ToHexString($header[16..19]), 16)
            $height = [Convert]::ToUInt32([Convert]::ToHexString($header[20..23]), 16)
            if ([Math]::Max($width, $height) -ne 512 -or [Math]::Min($width, $height) -lt 1) {
                throw "Renderer did not preserve the requested bounding box for $($job.Source.path)."
            }
            if ($header[25] -notin @(4, 6)) { throw "PNG is missing an alpha channel: $($job.Source.path)" }
        }
        $job.Hash = (Get-FileHash -LiteralPath $job.Temporary).Hash.ToLowerInvariant()
        $job.Bytes = (Get-Item -LiteralPath $job.Temporary).Length
        $job
    } -ThrottleLimit 4)
    if ($rendered.Count -ne $jobs.Count) { throw 'Not every planned output rendered successfully.' }

    # Check all destinations before installing any output; interrupted runs can resume.
    foreach ($job in $rendered) {
        if (Test-Path -LiteralPath $job.Destination) {
            if ((Get-FileHash -LiteralPath $job.Destination).Hash.ToLowerInvariant() -ne $job.Hash) {
                throw "Refusing to overwrite different content: $($job.Target)"
            }
        }
        if ((Get-FileHash -LiteralPath $job.SourcePath).Hash.ToLowerInvariant() -ne $job.Source.sha256) {
            throw "Source changed during rendering: $($job.Source.path)"
        }
    }
    foreach ($job in $rendered | Sort-Object Target) {
        $values = [ordered]@{}
        foreach ($field in $job.Row.PSObject.Properties.Name) { $values[$field] = $job.Row.$field }
        $values.action = 'generate'
        $values.original_path = "Generated\$($job.Method)\$($job.Target)"
        $values.path = $job.Target
        $values.sha256 = $job.Hash
        $values.bytes = [string]$job.Bytes
        $values.generation_method = $job.Method
        $values.derived_from = $job.Source.path
        $values.derived_from_sha256 = $job.Source.sha256
        $values.renderer = if ($job.Method -eq 'svg-to-png') { 'resvg 0.49.0 (Windows x64)' } else { '' }
        $values.render_longest_edge = if ($job.Method -eq 'svg-to-png') { '512' } else { '' }
        $values.captions = (@($job.Source.captions, [IO.Path]::GetFileNameWithoutExtension($job.Source.original_path)) |
            Where-Object { $_ } | Select-Object -Unique) -join '; '
        foreach ($field in @('source_url', 'source_revision', 'source_license', 'source_attribution')) {
            if ($job.Source.PSObject.Properties[$field]) { $values[$field] = $job.Source.$field }
        }
        if (-not (Test-Path -LiteralPath $job.Destination)) {
            [IO.Directory]::CreateDirectory((Split-Path $job.Destination -Parent)) | Out-Null
            [IO.File]::Move($job.Temporary, $job.Destination)
        }
        $rows.Add([pscustomobject]$values)
    }
    $temporaryMapping = Join-Path $staging 'migration.csv'
    $rows | Sort-Object original_path | Export-Csv -LiteralPath $temporaryMapping -NoTypeInformation -Encoding utf8
    # Staging can be on another volume, so copy to an adjacent file before replacing.
    $adjacent = $mappingPath + '.' + [guid]::NewGuid().ToString('N') + '.pending'
    try {
        [IO.File]::Copy($temporaryMapping, $adjacent, $false)
        [IO.File]::Move($adjacent, $mappingPath, $true)
    } finally {
        if (Test-Path -LiteralPath $adjacent) { [IO.File]::Delete($adjacent) }
    }
    $pngCount = @($rendered | Where-Object Method -eq 'svg-to-png').Count
    $svgCount = @($rendered | Where-Object Method -eq 'source-svg-copy').Count
    Write-Host "Added $pngCount PNGs at 512px longest edge and $svgCount byte-identical SVG counterparts. Existing artwork was not changed."
} finally {
    if (Test-Path -LiteralPath $staging) { [IO.Directory]::Delete($staging, $true) }
}
