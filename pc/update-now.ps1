# 썸네일 지금 갱신
# 1) 클라우드 Claude 작업(캔바 수정 + PNG를 GitHub에 올리기)을 바로 실행
# 2) GitHub에 새 커밋이 올라올 때까지 기다림
# 3) sync.ps1로 바탕화면 1.png, 2.png, 3.png 덮어쓰기
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$routineId = 'trig_01W7kQHbSV4GvU8T3o9mtF7V'
$repo      = 'GodlovesKJH/church-thumbnails'
$dir       = Join-Path $env:LOCALAPPDATA 'ChurchThumbnails'
$tokenFile = Join-Path $dir 'routine-token.dat'
$hdr       = @{ 'User-Agent' = 'church-thumbnail-sync' }
New-Item -ItemType Directory -Force -Path $dir | Out-Null

function To-Plain($s) { [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)) }

function Get-Token {
    if (Test-Path $tokenFile) {
        try { return To-Plain (Get-Content $tokenFile -Raw | ConvertTo-SecureString) } catch { }
    }
    Write-Host ''
    Write-Host '처음 한 번만 필요합니다.'
    Write-Host '예약 작업 화면에서 만든 API 토큰(sk-ant-oat01- 로 시작)을 붙여 넣고 Enter를 누르세요.'
    Write-Host '(붙여 넣어도 화면에는 * 로 보입니다. 마우스 오른쪽 클릭으로 붙여 넣기)'
    $s = Read-Host -AsSecureString '토큰'
    $plain = (To-Plain $s).Trim()
    if ($plain -notlike 'sk-ant-oat01-*') { throw '토큰 형식이 아닙니다. sk-ant-oat01- 로 시작하는 값을 넣어 주세요.' }
    # 이 PC의 이 사용자만 풀 수 있게 암호화해서 저장
    ($plain | ConvertTo-SecureString -AsPlainText -Force) | ConvertFrom-SecureString | Set-Content $tokenFile
    return $plain
}

function Get-Head { (Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/commits/main" -Headers $hdr -TimeoutSec 30).sha }

try {
    $token  = Get-Token
    $before = Get-Head

    Write-Host ''
    Write-Host '클라우드 작업을 시작합니다...'
    $body  = @{ text = ("교회 PC의 '썸네일 지금 갱신' 버튼으로 실행했습니다 ({0})." -f (Get-Date -Format 'yyyy-MM-dd HH:mm')) } | ConvertTo-Json -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($body)
    try {
        $r = Invoke-RestMethod -Method Post -Uri "https://api.anthropic.com/v1/claude_code/routines/$routineId/fire" `
             -Headers @{ Authorization = "Bearer $token"; 'anthropic-version' = '2026-10-21' } `
             -ContentType 'application/json; charset=utf-8' -Body $bytes -TimeoutSec 60
    } catch {
        $code = $null; try { $code = [int]$_.Exception.Response.StatusCode } catch { }
        if ($code -eq 401) { Remove-Item $tokenFile -ErrorAction SilentlyContinue; throw '토큰이 맞지 않습니다. 다시 실행해서 새 토큰을 넣어 주세요.' }
        if ($code -eq 400) { throw '예약 작업이 일시중지 상태입니다. 예약 작업 화면에서 「활성」으로 바꿔 주세요.' }
        if ($code -eq 429) { throw '1시간 실행 한도에 걸렸습니다. 잠시 뒤 다시 실행해 주세요.' }
        throw ("실행 요청 실패 ({0}): {1}" -f $code, $_.Exception.Message)
    }
    $url = $r.claude_code_session_url
    Write-Host "작업 진행 화면: $url"
    Write-Host ''
    Write-Host '캔바 수정과 PNG 올리기를 기다리는 중입니다(보통 1~3분, 최대 10분).'

    $after = $before
    $deadline = (Get-Date).AddMinutes(10)
    Start-Sleep -Seconds 40
    while ((Get-Date) -lt $deadline) {
        try { $after = Get-Head } catch { }
        if ($after -and $after -ne $before) { break }
        Write-Host -NoNewline '.'
        Start-Sleep -Seconds 20
    }
    Write-Host ''

    if ($after -eq $before) {
        Write-Host '[확인 필요] 10분 안에 결과가 올라오지 않았습니다. 작업 진행 화면을 엽니다.'
        Start-Process $url
        exit 1
    }

    # 작업이 남긴 결과 요약
    try {
        $note = Invoke-RestMethod -Uri "https://raw.githubusercontent.com/$repo/$after/last-run.txt" -Headers $hdr -TimeoutSec 30
        Write-Host '--- 작업 결과 ---'
        Write-Host $note
        Write-Host '----------------'
    } catch { }

    Write-Host '바탕화면 PNG를 받는 중입니다...'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dir 'sync.ps1')
    $log = Join-Path $dir 'sync.log'
    if (Test-Path $log) { Get-Content $log -Encoding UTF8 -Tail 2 | ForEach-Object { Write-Host $_ } }
    Write-Host ''
    Write-Host ("[완료] 커밋 {0} 내용으로 바탕화면 1.png, 2.png, 3.png 를 맞췄습니다." -f $after.Substring(0,7))
} catch {
    Write-Host ''
    Write-Host ("[실패] {0}" -f $_.Exception.Message)
    exit 1
}
