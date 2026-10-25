@echo off
chcp 65001 >nul
schtasks /Delete /TN "ChurchThumbnailSync" /F
rmdir /S /Q "%LOCALAPPDATA%\ChurchThumbnails"
echo 썸네일 자동 저장을 해제했습니다.
pause
