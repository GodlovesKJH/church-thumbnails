@echo off
chcp 65001 >nul
setlocal
title 썸네일 지금 갱신
set "DIR=%LOCALAPPDATA%\ChurchThumbnails"
set "RAW=https://raw.githubusercontent.com/GodlovesKJH/church-thumbnails/main/pc"
if not exist "%DIR%" mkdir "%DIR%"

rem 최신 스크립트 받기 (실패하면 이전에 받은 것을 사용)
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; foreach($f in 'update-now.ps1','sync.ps1'){ try { Invoke-WebRequest -UseBasicParsing -TimeoutSec 30 -Uri ('%RAW%/'+$f) -OutFile ('%DIR%\'+$f+'.new'); Move-Item -Force ('%DIR%\'+$f+'.new') ('%DIR%\'+$f) } catch { } }"

if not exist "%DIR%\update-now.ps1" (
  echo [실패] 스크립트를 받지 못했습니다. 인터넷 연결을 확인해 주세요.
  pause
  exit /b 1
)

echo 구글시트 입력을 마친 뒤 실행하세요. 캔바와 바탕화면 PNG를 함께 고칩니다.
powershell -NoProfile -ExecutionPolicy Bypass -File "%DIR%\update-now.ps1"
echo.
pause
