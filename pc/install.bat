@echo off
chcp 65001 >nul
setlocal
set "DEST=%LOCALAPPDATA%\ChurchThumbnails"
if not exist "%DEST%" mkdir "%DEST%"
copy /Y "%~dp0sync.ps1" "%DEST%\sync.ps1" >nul
copy /Y "%~dp0run-hidden.vbs" "%DEST%\run-hidden.vbs" >nul
copy /Y "%~dp0uninstall.bat" "%DEST%\uninstall.bat" >nul

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0register.ps1"
if errorlevel 1 (
  echo.
  echo [실패] 작업 스케줄러 등록에 실패했습니다. 이 창을 캡처해서 Claude에게 보여 주세요.
  pause
  exit /b 1
)

echo 지금 한 번 받아오는 중입니다...
powershell -NoProfile -ExecutionPolicy Bypass -File "%DEST%\sync.ps1"

echo.
echo [완료] 설치되었습니다.
echo  - 로그인할 때와 이후 1시간마다 바탕화면 1.png, 2.png, 3.png 를 최신으로 맞춥니다.
echo  - Claude 앱은 켜져 있지 않아도 됩니다.
echo  - 기록: %DEST%\sync.log
echo  - 해제하려면: %DEST%\uninstall.bat
echo  - 바탕화면의 thumbnail-sync 폴더는 이제 지워도 됩니다.
echo.
pause
