[CmdletBinding()]
param([Parameter(Mandatory)][string]$WorkDirectory)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$tool = Join-Path $PSScriptRoot 'manage-icons.ps1'
$fixture = Join-Path ([IO.Path]::GetFullPath($WorkDirectory)) ('icon-migration-test-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($fixture) | Out-Null

function Write-Fixture([string]$Relative, [string]$Content) {
    $path = Join-Path $fixture $Relative
    [IO.Directory]::CreateDirectory((Split-Path $path -Parent)) | Out-Null
    [IO.File]::WriteAllText($path, $Content)
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
    $svg = '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><path d="M0 0h32v32H0z"/></svg>'
    $rasterSvg = '<svg xmlns="http://www.w3.org/2000/svg" width="720" height="720"><image href="data:image/png;base64,iVBORw0KGgo="/></svg>'
    Write-Fixture 'AWS\Architecture-Service-Icons_test\Arch_Compute\32\Arch_Amazon-WorkSpaces_32.svg' $svg
    Write-Fixture 'AWS\Resource-Icons_test\Res_IoT\Res_AWS-IoT_Action_48_Dark.svg' $svg
    Write-Fixture 'AWS\__MACOSX\._image.svg' 'macOS metadata'
    Write-Fixture 'AWS\.DS_Store' 'Finder metadata'
    Write-Fixture 'Microsoft\Azure_Public_Service_Icons\Icons\compute\00001-icon-service-Workspaces.svg' $svg
    Write-Fixture 'Microsoft\Azure_Public_Service_Icons\Icons\compute\00002-icon-service-Workspaces.svg' $svg
    Write-Fixture 'Microsoft\Azure_Public_Service_Icons\Icons\ai + machine learning\00003-icon-service-Face-APIs.svg' $svg
    Write-Fixture 'Microsoft\Fabric Icons\dist\svg\add_pipeline_20_non-item.svg' $svg
    Write-Fixture 'Google\Unique Icons\Compute Engine\SVG\ComputeEngine-512-color-rgb.svg' $svg
    Write-Fixture 'MongoDB\MongoDB_Presentation_Icon_Kit\Atlas\Atlas-Charts.svg' $rasterSvg
    Write-Fixture 'MongoDB\MongoDB_Presentation_Icon_Kit\manifest.csv' @'
category,caption,slide,png,svg,width,height,sha256
Atlas,Atlas Charts,55,Atlas/Atlas-Charts.png,Atlas/Atlas-Charts.svg,720,720,unused
'@
    Write-Fixture 'MongoDB\MongoDB_Presentation_Icon_Kit\README.md' 'Original provenance'
    $pngPath = Join-Path $fixture 'AWS\Architecture-Service-Icons_test\Arch_Compute\64\Arch_Amazon-WorkSpaces_64@5x.png'
    [IO.Directory]::CreateDirectory((Split-Path $pngPath -Parent)) | Out-Null
    [IO.File]::WriteAllBytes($pngPath, [Convert]::FromBase64String(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a9XkAAAAASUVORK5CYII='))

    & $tool -Mode Plan -Root $fixture
    $mapping = @(Import-Csv -LiteralPath (Join-Path $fixture 'catalog\migration.csv'))
    $paths = @($mapping.path)
    Assert-True ($paths -contains 'svg\aws\compute\aws-service-amazon-workspaces--size-32.svg') 'WorkSpaces normalization failed.'
    Assert-True ($paths -contains 'png\aws\compute\aws-service-amazon-workspaces--size-64--scale-5x.png') 'Density variant lost.'
    Assert-True ($paths -contains 'svg\aws\iot\aws-resource-iot-action--theme-dark--size-48.svg') 'IoT or theme normalization failed.'
    Assert-True ($paths -contains 'svg\microsoft\azure\ai-machine-learning\microsoft-azure-service-face-apis.svg') 'Plural acronym normalization failed.'
    Assert-True (@($paths | Where-Object { $_ -like '*--source-id-*' }).Count -eq 2) 'Azure collisions not disambiguated.'
    Assert-True ($paths -contains 'svg\mongodb\atlas\mongodb-atlas-resource-charts.svg') 'MongoDB family directory repeated.'
    Assert-True (Test-Path -LiteralPath $pngPath) 'Plan changed source files.'
    Assert-Fails { & $tool -Mode Plan -Root $fixture } '*mapping already exists*'

    $conflict = Join-Path $fixture 'svg\aws\compute\aws-service-amazon-workspaces--size-32.svg'
    [IO.Directory]::CreateDirectory((Split-Path $conflict -Parent)) | Out-Null
    [IO.File]::WriteAllText($conflict, 'existing destination')
    Assert-Fails { & $tool -Mode Apply -Root $fixture } '*Destination already exists*'
    Assert-True (Test-Path -LiteralPath $pngPath) 'Failed preflight partially migrated files.'
    [IO.File]::Delete($conflict)

    & $tool -Mode Apply -Root $fixture
    & $tool -Mode Apply -Root $fixture
    & $tool -Mode Build -Root $fixture
    & $tool -Mode Validate -Root $fixture
    $catalogPath = Join-Path $fixture 'catalog\icons.json'
    $firstHash = (Get-FileHash -LiteralPath $catalogPath).Hash
    & $tool -Mode Build -Root $fixture
    Assert-True ((Get-FileHash -LiteralPath $catalogPath).Hash -eq $firstHash) 'Catalog output is not deterministic.'
    $catalog = Get-Content -LiteralPath $catalogPath -Raw | ConvertFrom-Json
    Assert-True (@($catalog.icons | Where-Object { $_.variants.color_space -eq 'rgb' }).Count -eq 1) 'RGB provenance lost.'
    Assert-True (@($catalog.icons | Where-Object { $_.image.artwork -eq 'raster-embedded' }).Count -eq 1) 'Raster wrapper classification failed.'
    [IO.File]::AppendAllText($conflict, 'tampered')
    Assert-Fails { & $tool -Mode Validate -Root $fixture } '*Checksum mismatch*'
    Assert-Fails { & $tool -Mode Build -Root $fixture } '*Checksum mismatch*'
    Write-Host 'Migration regression checks passed.'
} finally {
    # Delete only this test's uniquely named fixture, never the supplied work directory.
    if (Test-Path -LiteralPath $fixture) { [IO.Directory]::Delete($fixture, $true) }
}
