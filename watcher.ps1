# Obsidian Quick Sync watcher
# Watches this folder for new/changed .html files, updates pages.json,
# commits, and pushes to GitHub. Cloudflare Pages auto-deploys on push.

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $RepoRoot

$LogFile = Join-Path $RepoRoot 'watcher.log'
function Log($msg) {
  $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
  Write-Host $line
  Add-Content -Path $LogFile -Value $line
}

Log "Watcher starting in $RepoRoot"

# Files the watcher itself manages — ignore changes to these
$IgnoreNames = @('index.html', 'pages.json', 'README.md', '.gitignore',
                 'watcher.ps1', 'start-watcher.bat', 'watcher.log')

function Rebuild-PagesJson {
  $pages = @()
  Get-ChildItem -Path $RepoRoot -Filter *.html -File | ForEach-Object {
    if ($IgnoreNames -contains $_.Name) { return }
    $title = $_.BaseName
    try {
      $head = Get-Content -Path $_.FullName -TotalCount 40 -ErrorAction Stop -Raw
      if ($head -match '<title>([^<]+)</title>') { $title = $Matches[1].Trim() }
    } catch {}
    $pages += [pscustomobject]@{
      file  = $_.Name
      title = $title
      added = $_.LastWriteTime.ToString('yyyy-MM-dd')
    }
  }
  $json = if ($pages.Count -eq 0) { '[]' } else { $pages | ConvertTo-Json -Depth 3 -Compress }
  Set-Content -Path (Join-Path $RepoRoot 'pages.json') -Value $json -Encoding UTF8
}

function Sync-Now($reason) {
  try {
    Rebuild-PagesJson
    $status = git status --porcelain
    if (-not $status) { Log "No changes to commit ($reason)"; return }
    git add -A | Out-Null
    $msg = "sync: $reason ({0})" -f (Get-Date -Format 'yyyy-MM-dd HH:mm')
    git commit -m $msg | Out-Null
    git push origin HEAD | Out-Null
    Log "Pushed: $msg"
  } catch {
    Log "ERROR: $($_.Exception.Message)"
  }
}

# Initial sync (in case files were dropped while watcher was off)
Sync-Now "startup scan"

# Debounce: collect rapid events and sync once
$script:lastEvent = $null
$script:pending = $false

$watcher = New-Object System.IO.FileSystemWatcher $RepoRoot
$watcher.Filter = '*.*'
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite, Size'
$watcher.EnableRaisingEvents = $true

$action = {
  $path = $Event.SourceEventArgs.FullPath
  # Ignore .git internals and watcher-managed files
  if ($path -match '\\\.git\\') { return }
  $name = Split-Path $path -Leaf
  $ignore = @('index.html','pages.json','watcher.log','README.md','.gitignore','watcher.ps1','start-watcher.bat')
  if ($ignore -contains $name) { return }
  $script:lastEvent = Get-Date
  $script:pending = $true
}

Register-ObjectEvent $watcher Created -Action $action | Out-Null
Register-ObjectEvent $watcher Changed -Action $action | Out-Null
Register-ObjectEvent $watcher Renamed -Action $action | Out-Null
Register-ObjectEvent $watcher Deleted -Action $action | Out-Null

Log "Watching for file changes. Press Ctrl+C to stop."

try {
  while ($true) {
    Start-Sleep -Seconds 2
    if ($script:pending -and $script:lastEvent) {
      $elapsed = (Get-Date) - $script:lastEvent
      if ($elapsed.TotalSeconds -ge 3) {
        $script:pending = $false
        Sync-Now "file change"
      }
    }
  }
} finally {
  $watcher.EnableRaisingEvents = $false
  $watcher.Dispose()
  Log "Watcher stopped."
}
