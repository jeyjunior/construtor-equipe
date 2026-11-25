@echo off
rem Abre o instalar.sh no Git Bash (o bash do PowerShell pode ser o do WSL).
for /f "delims=" %%G in ('git --exec-path') do set "GIT_EXEC=%%G"
if not defined GIT_EXEC (
  echo Git nao encontrado. Instale o Git for Windows: https://git-scm.com/download/win
  pause
  exit /b 1
)
"%GIT_EXEC%\..\..\..\bin\bash.exe" "%~dp0instalar.sh" %*
pause
