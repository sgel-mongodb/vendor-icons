#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RendererPath,
    [Parameter(Mandatory)][string]$WorkDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$sync = Join-Path $PSScriptRoot 'sync-icon-formats.ps1'
$manager = Join-Path $PSScriptRoot 'manage-icons.ps1'
$fixture = Join-Path ([IO.Path]::GetFullPath($WorkDirectory)) ('icon-format-test-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory((Join-Path $fixture 'catalog')) | Out-Null
$mappingPath = Join-Path $fixture 'catalog\migration.csv'
$rows = [Collections.Generic.List[object]]::new()

function Add-Fixture([string]$Relative, [byte[]]$Bytes, [string]$Vendor, [string]$Component) {
    $path = Join-Path $fixture $Relative
    [IO.Directory]::CreateDirectory((Split-Path $path -Parent)) | Out-Null
    [IO.File]::WriteAllBytes($path, $Bytes)
    $rows.Add([pscustomobject][ordered]@{
        action = 'move'; role = 'icon'; original_path = 'fixture-source\' + $Relative
        path = $Relative; sha256 = (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()
        bytes = [string]$Bytes.Length; vendor = $Vendor; family = ''; category = ''; kind = 'resource'
        component = $Component; style = ''; theme = ''; size = ''; scale = ''; source_id = ''; color_space = ''
        captions = ''; source_slides = ''; source_url = ''; source_revision = ''; source_license = ''; source_attribution = ''
    })
}

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Assert-Fails([scriptblock]$Operation, [string]$Pattern) {
    $message = ''
    try { & $Operation } catch { $message = $_.Exception.Message }
    if (-not $message -or $message -notlike $Pattern) {
        throw "Expected failure '$Pattern'; received '$message'."
    }
}

try {
    $square = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20"><rect x="5" y="5" width="10" height="10" fill="red"/></svg>'
    $wide = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 10"><rect x="1" y="1" width="38" height="8" fill="blue"/></svg>'
    $png = [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9XkAAAAASUVORK5CYII=')
    Add-Fixture 'svg\redhat\standard\redhat-resource-square.svg' ([Text.Encoding]::UTF8.GetBytes($square)) 'redhat' 'square'
    $rows[0].source_url = 'https://example.test/square.svg'
    $rows[0].source_revision = 'fixture'
    $rows[0].source_license = 'CC-BY-4.0'
    $rows[0].source_attribution = 'Fixture author'
    Add-Fixture 'svg\capgemini\capgemini-resource-wide.svg' ([Text.Encoding]::UTF8.GetBytes($wide)) 'capgemini' 'wide'
    Add-Fixture 'svg\aws\compute\aws-resource-server--size-64.svg' ([Text.Encoding]::UTF8.GetBytes($square)) 'aws' 'server'
    Add-Fixture 'png\aws\compute\aws-resource-server--size-64.png' $png 'aws' 'server'
    Add-Fixture 'png\aws\compute\aws-resource-server--size-64--scale-5x.png' $png 'aws' 'server'
    $rows[4].scale = '5x'
    $rows | Export-Csv -LiteralPath $mappingPath -NoTypeInformation -Encoding utf8
    & $manager -Root $fixture -Mode Build
    Assert-Fails { & $manager -Root $fixture -Mode Validate -RequirePairs } '*Missing format counterpart*'

    $invalidRenderer = Join-Path $fixture 'invalid-renderer.exe'
    [IO.File]::WriteAllText($invalidRenderer, 'Not the approved renderer')
    Assert-Fails { & $sync -Root $fixture -RendererPath $invalidRenderer } '*Renderer checksum does not match*'
    [IO.File]::Delete($invalidRenderer)

    Add-Fixture 'png\aws\aws-resource-no-vector.png' $png 'aws' 'no-vector'
    $rows | Export-Csv -LiteralPath $mappingPath -NoTypeInformation -Encoding utf8
    Assert-Fails { & $sync -Root $fixture -RendererPath $RendererPath } '*No existing vector source*'
    [IO.File]::Delete((Join-Path $fixture $rows[5].path))
    $rows.RemoveAt(5)
    $rows | Export-Csv -LiteralPath $mappingPath -NoTypeInformation -Encoding utf8
    $before = (Get-FileHash -LiteralPath $mappingPath).Hash

    $counterpart = Join-Path $fixture 'png\redhat\standard\redhat-resource-square.png'
    [IO.Directory]::CreateDirectory((Split-Path $counterpart -Parent)) | Out-Null
    [IO.File]::WriteAllText($counterpart, 'Existing unrelated content')
    Assert-Fails { & $sync -Root $fixture -RendererPath $RendererPath } '*Refusing to overwrite different content*'
    Assert-True ((Get-FileHash -LiteralPath $mappingPath).Hash -eq $before) 'Failed preflight changed the mapping.'
    [IO.File]::Delete($counterpart)

    & $sync -Root $fixture -RendererPath $RendererPath
    & $manager -Root $fixture -Mode Build
    & $manager -Root $fixture -Mode Validate -RequirePairs
    foreach ($row in $rows) {
        Assert-True ((Get-FileHash -LiteralPath (Join-Path $fixture $row.path)).Hash.ToLowerInvariant() -eq $row.sha256) 'Original artwork was changed.'
    }
    $catalogPath = Join-Path $fixture 'catalog\icons.json'
    $catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
    Assert-True ($catalog.asset_count -eq 8) 'Unexpected synchronized asset count.'
    $widePng = @($catalog.icons | Where-Object path -eq 'png\capgemini\capgemini-resource-wide.png')[0]
    Assert-True ($widePng.image.width -eq 512 -and $widePng.image.height -eq 128) 'Aspect ratio was not preserved.'
    $squarePng = @($catalog.icons | Where-Object path -eq 'png\redhat\standard\redhat-resource-square.png')[0]
    Assert-True ($squarePng.source.license -eq 'CC-BY-4.0' -and $squarePng.derivation.method -eq 'svg-to-png') 'Derived artwork lost its provenance.'
    Add-Type -AssemblyName System.Drawing.Common
    $bitmap = [Drawing.Bitmap]::new((Join-Path $fixture $squarePng.path))
    try {
        Assert-True ($bitmap.GetPixel(0, 0).A -eq 0) 'Transparent SVG margins became opaque.'
        $center = $bitmap.GetPixel(256, 256)
        Assert-True ($center.A -eq 255 -and $center.R -eq 255 -and $center.G -eq 0 -and $center.B -eq 0) 'Rendered artwork is blank or changed color.'
    } finally { $bitmap.Dispose() }
    $copied = @($catalog.icons | Where-Object path -eq 'svg\aws\compute\aws-resource-server--size-64--scale-5x.svg')[0]
    Assert-True ($copied.sha256 -eq $rows[2].sha256 -and $copied.derivation.method -eq 'source-svg-copy') 'AWS vector source was not copied intact.'
    $mappingHash = (Get-FileHash -LiteralPath $mappingPath).Hash
    & $sync -Root $fixture -RendererPath $RendererPath
    Assert-True ((Get-FileHash -LiteralPath $mappingPath).Hash -eq $mappingHash) 'Repeated sync changed the mapping.'
    $squarePng.derivation.source_sha256 = 'incorrect'
    $catalog | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $catalogPath -Encoding utf8
    Assert-Fails { & $manager -Root $fixture -Mode Validate -RequirePairs } '*Catalog derivation mismatch*'
    Write-Host 'Format synchronization regression checks passed.'
} finally {
    if (Test-Path -LiteralPath $fixture) { [IO.Directory]::Delete($fixture, $true) }
}
