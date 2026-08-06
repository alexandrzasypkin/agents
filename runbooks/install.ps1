#!/usr/bin/env pwsh
# install.ps1 — NATIVE-Windows counterpart of install.sh. Brings up ~/.agents from the public repo.
#
# Distribution model: PUBLIC repo — READ-ONLY for consumers, edits only on the OWNER machine.
#   Consumers clone/pull anonymously over HTTPS (no key, no login); write is owner-only (SSH).
#
# One-shot (PowerShell):
#   irm https://raw.githubusercontent.com/alexandrzasypkin/agents/master/runbooks/install.ps1 | iex
#   ALSO install baseline-guard:  $env:AGENTS_BASELINE_GUARD=1; irm <same-url> | iex
# Or clone-first (then the -InstallBaselineGuard switch is available):
#   git clone https://github.com/alexandrzasypkin/agents.git $HOME\.agents; & $HOME\.agents\runbooks\install.ps1 -InstallBaselineGuard
#
# Requires: Git for Windows (git in PATH). SYMLINKS need Developer Mode ON (Settings > For developers)
# or an elevated shell — the script tells you if that is missing. (Under WSL2 / Git Bash use install.sh.)

param([switch]$InstallBaselineGuard)
$ErrorActionPreference = 'Stop'
$DoGuard = $InstallBaselineGuard -or ($env:AGENTS_BASELINE_GUARD -eq '1')

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

# 3. baseline-guard -- the ONE global guardrail bootstrap never writes. Auto-install ONLY with
#    -InstallBaselineGuard (or $env:AGENTS_BASELINE_GUARD=1 for the one-shot); else guide. Idempotent.
$GuardDir = Join-Path $Dest 'hooks\baseline-guard'
$configs  = @((Join-Path $HOME '.claude\settings.json'), (Join-Path $HOME '.codex\config.toml'))
$hasGuard = $false
foreach ($c in $configs) {
    if ((Test-Path $c) -and (Select-String -Quiet -Pattern 'baseline-guard' -Path $c)) { $hasGuard = $true }
}
if ($DoGuard) {
    Write-Host '== installing baseline-guard =='
    # codex -- append the TOML section (safe: array-of-tables at EOF)
    if ((Get-Command codex -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $HOME '.codex'))) {
        $cfg = Join-Path $HOME '.codex\config.toml'
        if ((Test-Path $cfg) -and (Select-String -Quiet 'baseline-guard' $cfg)) {
            Write-Host '   codex: already present -- skipped'
        } else {
            New-Item -ItemType Directory -Force -Path (Split-Path $cfg) | Out-Null
            "`n" + (Get-Content (Join-Path $GuardDir 'codex.toml') -Raw) | Add-Content -Path $cfg
            Write-Host "   codex: appended -> $cfg"
        }
    }
    # claude -- JSON merge (native); missing file = write verbatim; malformed = leave it, guide
    if ((Get-Command claude -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $HOME '.claude'))) {
        $cfg = Join-Path $HOME '.claude\settings.json'
        if ((Test-Path $cfg) -and (Select-String -Quiet 'baseline-guard' $cfg)) {
            Write-Host '   claude: already present -- skipped'
        } elseif (-not (Test-Path $cfg)) {
            New-Item -ItemType Directory -Force -Path (Split-Path $cfg) | Out-Null
            Copy-Item (Join-Path $GuardDir 'claude.json') $cfg -Force
            Write-Host "   claude: written -> $cfg"
        } else {
            try {
                $obj  = Get-Content $cfg -Raw | ConvertFrom-Json
                $frag = Get-Content (Join-Path $GuardDir 'claude.json') -Raw | ConvertFrom-Json
                if (-not $obj.hooks) { $obj | Add-Member -NotePropertyName hooks -NotePropertyValue ([pscustomobject]@{}) }
                if (-not $obj.hooks.PreToolUse) { $obj.hooks | Add-Member -NotePropertyName PreToolUse -NotePropertyValue @() }
                $obj.hooks.PreToolUse += $frag.hooks.PreToolUse
                $obj | ConvertTo-Json -Depth 20 | Set-Content -Path $cfg
                Write-Host "   claude: merged -> $cfg"
            } catch {
                Write-Warning "   claude: settings.json couldn't be parsed/merged -- merge by hand ($_)"
            }
        }
    }
    # opencode -- copy plugin file (safe: standalone .ts)
    if ((Get-Command opencode -ErrorAction SilentlyContinue) -or (Test-Path (Join-Path $HOME '.config\opencode'))) {
        $pdir = Join-Path $HOME '.config\opencode\plugin'
        New-Item -ItemType Directory -Force -Path $pdir | Out-Null
        Copy-Item (Join-Path $GuardDir 'opencode.ts') (Join-Path $pdir 'baseline-guard.ts') -Force
        Write-Host "   opencode: plugin -> $pdir\baseline-guard.ts"
    }
    # The fragments run a bash script (`bash "..."`, guard.sh is #!/usr/bin/env bash). On native
    # Windows the hook fires ONLY through Git Bash — verify bash is reachable, else the guard is inert.
    if (-not (Get-Command bash -ErrorAction SilentlyContinue)) {
        Write-Warning 'baseline-guard runs a bash script, but `bash` is not on PATH.'
        Write-Warning 'On native Windows the hook fires only via Git Bash: add Git''s usr\bin to PATH (or'
        Write-Warning 'install Git Bash), or have the agent adapt guard.sh to its shell (canon: hooks are'
        Write-Warning 'POSIX; on native Windows the agent adapts them per its environment).'
    }
} elseif ($hasGuard) {
    Write-Host '== baseline-guard: already present in a global agent config =='
} else {
    Write-Host '== baseline-guard NOT installed -- the guardrail that makes writes to ~/.agents need your approval =='
    Write-Host '   auto-install: re-run with -InstallBaselineGuard   (one-shot: $env:AGENTS_BASELINE_GUARD=1; irm <url> | iex)'
    Write-Host "   by hand: merge $GuardDir\{claude.json,codex.toml}; copy opencode.ts -> ~/.config/opencode/plugin (README > Setup)"
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
