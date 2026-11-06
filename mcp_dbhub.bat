@echo off
rem Arranca en esta carpeta para que DBHub lea .env y dbhub.toml.
cd /d "%~dp0"
node "%~dp0node_modules\@bytebase\dbhub\dist\index.js" --config=dbhub.toml --transport=stdio
