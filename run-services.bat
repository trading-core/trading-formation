@echo off
REM Script to manage Docker Compose services for trading-formation

if "%1"=="start" goto start
if "%1"=="stop" goto stop
if "%1"=="delete" goto delete
if "%1"=="restart" goto restart
goto help

:start
echo Starting services with build...
docker compose up --build -d
goto end

:stop
echo Pausing services...
docker compose stop
goto end

:delete
echo Deleting services...
docker compose down
goto end

:restart
echo Restarting services...
docker compose down
docker compose up --build -d
goto end

:help
echo Usage: %0 {start|stop|delete|restart}
echo   start   - Build and start services in detached mode
echo   stop    - Pause services (containers remain)
echo   delete  - Stop and remove all services
echo   restart - Stop, rebuild, and restart services
goto end

:end