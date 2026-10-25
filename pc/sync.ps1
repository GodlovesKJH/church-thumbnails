# 높은뜻안성교회 썸네일 → 바탕화면 1.png, 2.png, 3.png 동기화
# GitHub 저장소 GodlovesKJH/church-thumbnails 의 최신 PNG를 받아, 바뀐 것만 덮어씁니다.
$ErrorActionPreference = 'Stop'
$repo    = 'GodlovesKJH/church-thumbnails'
$desktop = [Environment]::GetFolderPath('Desktop')
$logDir  = Join-Path $env:LOCALAPPDATA 'ChurchThumbnails'
$log     = Join-Path $logDir 'sync.log'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Log($msg) {
    $line = '{0}  {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $msg
    Add-Content -Path $log -Value $line -Encoding UTF8
}

# 네트워크가 막 켜진 직후일 수 있으므로 최대 5번(약 5분) 재시도
$sha = $null
for ($try = 1; $try -le 5 -and -not $sha; $try++) {
    try {
        $commit = Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/commits/main" -Headers @{ 'User-Agent' = 'church-thumbnail-sync' } -TimeoutSec 30
        $sha = $commit.sha
    } catch {
        if ($try -lt 5) { Start-Sleep -Seconds 60 } else { Write-Log "실패: GitHub 연결 안 됨 - $($_.Exception.Message)"; exit 1 }
    }
}

$tmp = Join-Path $logDir 'tmp'
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$changed = @()
foreach ($n in 1..3) {
    $name = "$n.png"
    $dl   = Join-Path $tmp $name
    $dest = Join-Path $desktop $name
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/$repo/$sha/$name" -OutFile $dl -UseBasicParsing -TimeoutSec 60
    } catch {
        Write-Log "실패: $name 다운로드 - $($_.Exception.Message)"; continue
    }
    $same = (Test-Path $dest) -and ((Get-FileHash $dl).Hash -eq (Get-FileHash $dest).Hash)
    if (-not $same) {
        try { Copy-Item $dl $dest -Force; $changed += $name }
        catch { Write-Log "실패: $name 저장(파일이 열려 있을 수 있음) - $($_.Exception.Message)" }
    }
}
if ($changed.Count) { Write-Log ("갱신: " + ($changed -join ', ') + "  (커밋 $($sha.Substring(0,7)))") }

# 로그가 너무 길어지지 않게 마지막 200줄만 유지
$lines = Get-Content $log -Encoding UTF8 -ErrorAction SilentlyContinue
if ($lines.Count -gt 200) { $lines | Select-Object -Last 200 | Set-Content $log -Encoding UTF8 }
