$ErrorActionPreference = 'Stop'

$RepoUrl = if ($env:AGENT_LIGHT_WORKFLOW_REPO_URL) { $env:AGENT_LIGHT_WORKFLOW_REPO_URL } else { 'https://github.com/ZhcChen/agent-light-workflow.git' }
$InstallRoot = if ($env:AGENT_LIGHT_WORKFLOW_INSTALL_ROOT) { $env:AGENT_LIGHT_WORKFLOW_INSTALL_ROOT } else { Join-Path $HOME '.agent-light-workflow' }
$RepoDir = Join-Path $InstallRoot 'repo'
$UserBin = if ($env:AGENT_LIGHT_WORKFLOW_USER_BIN) { $env:AGENT_LIGHT_WORKFLOW_USER_BIN } else { Join-Path $InstallRoot 'bin' }
$WrapperCmd = Join-Path $UserBin 'agent-light-workflow.cmd'
$SkipPathUpdate = if ($env:AGENT_LIGHT_WORKFLOW_SKIP_PATH_UPDATE) { $env:AGENT_LIGHT_WORKFLOW_SKIP_PATH_UPDATE } else { '0' }

function Write-Step {
  param([string]$Message)
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Ensure-WingetPackage {
  param(
    [string]$CommandName,
    [string]$WingetId,
    [string]$DisplayName
  )

  if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
    return
  }

  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget is required to install $DisplayName automatically. Install winget or install $DisplayName manually, then rerun this script."
  }

  Write-Step "Installing $DisplayName via winget"
  winget install --id $WingetId -e --accept-package-agreements --accept-source-agreements
}

function Refresh-CommonPathHints {
  $possible = @(
    'C:\Program Files\Git\cmd',
    'C:\Program Files\Git\bin',
    'C:\Program Files\Git\usr\bin'
  )

  foreach ($entry in $possible) {
    if ((Test-Path $entry) -and ($env:Path -notlike "*$entry*")) {
      $env:Path = "$entry;$env:Path"
    }
  }
}

function Resolve-GitBashPath {
  $candidates = @(
    (Get-Command bash -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue),
    'C:\Program Files\Git\bin\bash.exe',
    'C:\Program Files\Git\usr\bin\bash.exe'
  ) | Where-Object { $_ }

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return $candidate
    }
  }

  throw 'Git Bash was not found after Git installation.'
}

function Clone-Or-UpdateRepo {
  New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null

  if (Test-Path (Join-Path $RepoDir '.git')) {
    Write-Step "Updating existing repository in $RepoDir"
    git -C $RepoDir pull --ff-only
    return
  }

  if (Test-Path $RepoDir) {
    Remove-Item -Recurse -Force $RepoDir
  }

  Write-Step "Cloning repository into $RepoDir"
  git clone $RepoUrl $RepoDir
}

function Create-Wrappers {
  $gitBashPath = Resolve-GitBashPath
  New-Item -ItemType Directory -Force -Path $UserBin | Out-Null

  @"
@echo off
"$gitBashPath" "$RepoDir\init.sh" %*
"@ | Set-Content -Path $WrapperCmd -Encoding Ascii

  Write-Step "Installed command wrapper at $WrapperCmd"
}

function Ensure-UserPath {
  if ($SkipPathUpdate -eq '1') {
    Write-Step 'Skipping PATH update because AGENT_LIGHT_WORKFLOW_SKIP_PATH_UPDATE=1'
    return
  }

  $currentUserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  if (-not $currentUserPath) {
    $currentUserPath = ''
  }

  $parts = @($currentUserPath -split ';' | Where-Object { $_ -ne '' })
  if ($parts -contains $UserBin) {
    return
  }

  $parts = @($UserBin) + $parts
  $newUserPath = ($parts -join ';')
  [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
  $env:Path = "$UserBin;$env:Path"
  Write-Step "Added $UserBin to user PATH"
  Write-Step 'Open a new terminal after this script finishes.'
}

Ensure-WingetPackage -CommandName git -WingetId 'Git.Git' -DisplayName 'Git'
Refresh-CommonPathHints
Clone-Or-UpdateRepo
Create-Wrappers
Ensure-UserPath

Write-Step 'Done'
Write-Step 'Verify with: agent-light-workflow --help'
Write-Step 'Initialize with: agent-light-workflow .'
