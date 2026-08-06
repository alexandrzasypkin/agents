#!/usr/bin/env pwsh
# install.ps1 — NATIVE-Windows counterpart of install.sh. Brings up ~/.agents from the public repo.
#
# Distribution model: PUBLIC repo — READ-ONLY for consumers, edits only on the OWNER machine.
#   Consumers clone/pull anonymously over HTTPS (no key, no login); write is owner-only (SSH).
#
# One-shot (PowerShell):
#   irm https://raw.githubusercontent.com/alexandrzasypkin/agents/master/runbooks/install.ps1 | iex
# Or clone-first:
#   git clone https://github.com/alexandrzasypkin/agents.git $HOME\.agents; & $HOME\.agents\runbooks\install.ps1
#
# Requires: Git for Windows (git in PATH). SYMLINKS need Developer Mode ON (Settings > For developers)
# or an elevated shell — the script tells you if that is missing. (Under WSL2 / Git Bash use install.sh.)

$ErrorActionPreference = 'Stop'

$Repo  = if ($env:AGENTS_REPO) { $env:AGENTS_REPO } else { 'https://github.com/alexandrzasypkin/agents.git' }
$Dest  = Join-Path $HOME '.agents'
$Canon = Join-Path $Dest 'AGENTS.md'

function Git-OrThrow {
    param([string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed (exit $LASTEXITCODE)" }
}

# 1. Clone read-only, or pull if already present (never clobber an existing checkout).
if (Test-Path (Join-Path $Dest '.git')) {
    Write-Host '== ~/.agents already a git repo -- pulling latest (read-only) =='
    Git-OrThrow @('-C', $Dest, 'pull', '--ff-only')   # fast-forward or safely refuse; no overwrite
} else {
    Write-Host "== cloning $Repo -> $Dest =="
    Git-OrThrow @('clone', $Repo, $Dest)
}

# 2. Global symlinks -- ONLY for agents present on this host (not all 3 need be installed).
#    An agent counts as present if its CLI is in PATH or its config dir exists. -Force replaces a link.
function Link-Agent {
    param($Name, $Cli, $Dir, $Link)
    $present = (Get-Command $Cli -ErrorAction SilentlyContinue) -or (Test-Path $Dir)
    if ($present) {
        New-Item -ItemType Directory -Force -Path $Dir | Out-Null
        try {
            New-Item -ItemType SymbolicLink -Force -Path $Link -Target $Canon | Out-Null
            Write-Host "== ${Name}: linked $Link -> ~/.agents/AGENTS.md =="
        } catch {
            Write-Warning "${Name} symlink failed for ${Link}: $_"
            Write-Warning 'Enable Developer Mode (Settings > For developers) or run elevated, then re-run install.ps1.'
        }
    } else {
        Write-Host "== ${Name}: not detected -- skipped =="
    }
}
Link-Agent 'claude' 'claude' (Join-Path $HOME '.claude') (Join-Path $HOME '.claude\CLAUDE.md')  # Claude reads CLAUDE.md
Link-Agent 'codex'  'codex'  (Join-Path $HOME '.codex')  (Join-Path $HOME '.codex\AGENTS.md')   # Codex reads AGENTS.md
if (Get-Command 'opencode' -ErrorAction SilentlyContinue) {
    Write-Host '== opencode: detected -- reads ~/.agents natively, no symlink =='
}

# 3. baseline-guard -- the ONE global guardrail bootstrap never writes (install by hand, once).
$configs  = @((Join-Path $HOME '.claude\settings.json'), (Join-Path $HOME '.codex\config.toml'))
$hasGuard = $false
foreach ($c in $configs) {
    if ((Test-Path $c) -and (Select-String -Quiet -Pattern 'baseline-guard' -Path $c)) { $hasGuard = $true }
}
if ($hasGuard) {
    Write-Host '== baseline-guard: already present in a global agent config =='
} else {
    Write-Host '== ACTION: install baseline-guard into each agent GLOBAL config (by hand, once) =='
    Write-Host "   Fragments: $Dest\hooks\baseline-guard\{claude.json,codex.toml,opencode.ts}"
    Write-Host '   It makes every write to ~/.agents need explicit approval (protects the shared baseline).'
}

# 4. Integrity -- dynamic (no hardcoded SHA); trust anchor = commit SHA over HTTPS/TLS.
Write-Host '== integrity =='
Write-Host "   HEAD: $(& git -C $Dest rev-parse HEAD)"
if (& git -C $Dest status --porcelain) {
    Write-Warning 'working tree is DIRTY -- a read-only consumer must be clean (local edits = tampering/drift).'
}
$tag = $null
try { $tag = (& git -C $Dest describe --tags --abbrev=0 --match 'snapshot-*' 2>$null) } catch { }
if ($tag) {
    Write-Host "   latest snapshot: $tag -> $(& git -C $Dest rev-parse --short "$tag^{commit}")"
}
Write-Host '   trust anchor: commit SHA over HTTPS/TLS (SHA-only model; tags are not GPG-signed).'

Write-Host '== done. ~/.agents is read-only here; edits happen on the owner machine. =='
