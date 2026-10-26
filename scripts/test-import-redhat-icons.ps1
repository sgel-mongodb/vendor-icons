#requires -Version 7.4
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ArchivePath,
    [Parameter(Mandatory)][string]$WorkDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$importer = Join-Path $PSScriptRoot 'import-redhat-icons.ps1'
$manager = Join-Path $PSScriptRoot 'manage-icons.ps1'
$fixture = Join-Path ([IO.Path]::GetFullPath($WorkDirectory)) ('redhat-import-test-' + [guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory((Join-Path $fixture 'catalog')) | Out-Null
[IO.Directory]::CreateDirectory((Join-Path $fixture 'docs')) | Out-Null
[IO.Directory]::CreateDirectory((Join-Path $fixture 'png')) | Out-Null

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
    $notice = Join-Path $fixture 'docs\fixture-notice.txt'
    [IO.File]::WriteAllText($notice, 'Fixture provenance')
    $mappingPath = Join-Path $fixture 'catalog\migration.csv'
    [pscustomobject][ordered]@{
        action = 'move'; role = 'documentation'; original_path = 'fixture-source\notice.txt'
        path = 'docs\fixture-notice.txt'; sha256 = (Get-FileHash -LiteralPath $notice).Hash.ToLowerInvariant()
        bytes = (Get-Item -LiteralPath $notice).Length; vendor = ''; family = ''; category = ''; kind = ''
        component = ''; style = ''; theme = ''; size = ''; scale = ''; source_id = ''; color_space = ''
        captions = ''; source_slides = ''
    } | Export-Csv -LiteralPath $mappingPath -NoTypeInformation -Encoding utf8
    $originalMappingHash = (Get-FileHash -LiteralPath $mappingPath).Hash
    $invalidArchive = Join-Path $fixture 'invalid.zip'
    [IO.File]::WriteAllText($invalidArchive, 'Not the pinned archive')
    Assert-Fails { & $importer -Root $fixture -ArchivePath $invalidArchive } '*Archive checksum does not match*'
    [IO.File]::Delete($invalidArchive)

    $container = Join-Path $fixture 'svg\redhat\standard\redhat-resource-container--style-standard.svg'
    [IO.Directory]::CreateDirectory((Split-Path $container -Parent)) | Out-Null
    [IO.File]::WriteAllText($container, 'Existing unrelated content')
    Assert-Fails { & $importer -Root $fixture -ArchivePath $ArchivePath } '*Refusing to overwrite different content*'
    Assert-True ((Get-FileHash -LiteralPath $mappingPath).Hash -eq $originalMappingHash) 'Failed import changed the mapping.'
    Assert-True (@(Get-ChildItem -LiteralPath (Join-Path $fixture 'svg') -Recurse -File).Count -eq 1) 'Failed preflight partially imported icons.'
    [IO.File]::Delete($container)

    & $importer -Root $fixture -ArchivePath $ArchivePath
    $firstMappingHash = (Get-FileHash -LiteralPath $mappingPath).Hash
    & $importer -Root $fixture -ArchivePath $ArchivePath
    Assert-True ((Get-FileHash -LiteralPath $mappingPath).Hash -eq $firstMappingHash) 'Reimport changed the mapping.'
    & $manager -Root $fixture -Mode Build
    & $manager -Root $fixture -Mode Validate
    $catalog = Get-Content -LiteralPath (Join-Path $fixture 'catalog\icons.json') -Raw | ConvertFrom-Json
    Assert-True ($catalog.asset_count -eq 1193) 'Unexpected Red Hat coverage.'
    Assert-True (@($catalog.icons | Where-Object { $_.source.license -ne 'CC-BY-4.0' }).Count -eq 0) 'Artwork license metadata missing.'
    Assert-True (@($catalog.icons | Where-Object { $_.image.artwork -ne 'vector' }).Count -eq 0) 'Unexpected non-vector asset.'
    $mcp = @($catalog.icons | Where-Object name -eq 'redhat-resource-mcp-server--style-standard')[0]
    Assert-True ($mcp.aliases -contains 'Model Context Protocol server') 'MCP search alias missing.'
    [IO.File]::AppendAllText($container, 'tampered')
    Assert-Fails { & $importer -Root $fixture -ArchivePath $ArchivePath } '*Refusing to overwrite different content*'
    Assert-Fails { & $manager -Root $fixture -Mode Validate } '*Checksum mismatch*'
    Write-Host 'Red Hat import regression checks passed.'
} finally {
    if (Test-Path -LiteralPath $fixture) { [IO.Directory]::Delete($fixture, $true) }
}
