@echo off
rem Carrega o ambiente do Visual Studio e roda compilar_pc.ps1 (gera o C++ do jogo e compila a versao de PC).
rem Baseado em scripts\2_compilar.cmd de KIexster/god-of-war-recomp (GPLv3).
cd /d "%~dp0..\.."
if not exist gow\logs mkdir gow\logs
echo ==========================================================
echo  Compilando a versao de PC. A primeira vez leva 20-40 min.
echo  O progresso fica em gow\logs\2_compilar_pc.log
echo ==========================================================
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VSPATH="
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSPATH=%%i"
if not defined VSPATH (
  echo Visual Studio com C++ nao encontrado. > gow\logs\2_compilar_pc.log
  echo Visual Studio com C++ nao encontrado. Rode primeiro gow\windows\1_instalar.cmd
  pause
  exit /b 1
)
set VSCMD_SKIP_SENDTELEMETRY=1
call "%VSPATH%\VC\Auxiliary\Build\vcvars64.bat" > gow\logs\vcvars.log 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0compilar_pc.ps1" %* > gow\logs\2_compilar_pc.log 2>&1
set "RC=%errorlevel%"
echo [codigo final %RC%] >> gow\logs\2_compilar_pc.log
echo.
if "%RC%"=="0" (echo Terminou com sucesso.) else (echo Deu erro. Mande o arquivo gow\logs\2_compilar_pc.log)
pause
exit /b %RC%
