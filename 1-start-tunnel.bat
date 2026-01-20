@echo off
REM STEP 1: Start Cloudflare Tunnel

echo =========================================================
echo PIGRECO - Cloudflare Tunnel
echo =========================================================
echo.
echo Starting tunnel... Watch for a URL like:
echo   https://abc-xyz-123.trycloudflare.com
echo.
echo Copy that URL, then open a NEW terminal and run:
echo   2-deploy.bat
echo.
echo Keep this window OPEN to maintain the tunnel!
echo =========================================================
echo.

.\cloudflared.exe tunnel --url http://localhost:3000
