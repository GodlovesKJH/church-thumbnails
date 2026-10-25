@echo off
chcp 65001 >nul
cd /d "%TEMP%"
(
  schtasks /Delete /TN "ChurchThumbnailSync" /F >nul 2>&1
  rmdir /S /Q "%LOCALAPPDATA%\ChurchThumbnails" >nul 2>&1
  echo 썸네일 자동 저장을 해제했습니다. 바탕화면의 1.png, 2.png, 3.png 는 그대로 둡니다.
  pause
)
