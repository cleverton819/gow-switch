@echo off
rem Instala Git, Python 3.11 e Visual Studio 2022 Build Tools (C++, CMake e Ninja inclusos).
rem Baseado em scripts\1_instalar_herramientas.cmd de KIexster/god-of-war-recomp (GPLv3).
cd /d "%~dp0..\.."
if not exist gow\logs mkdir gow\logs
echo ==========================================================
echo  Instalando Git, Python e Visual Studio 2022 Build Tools (C++)
echo  O Windows vai pedir permissao de administrador: aceite.
echo  Pode levar 15-30 minutos. Nao feche esta janela.
echo ==========================================================
echo [%date% %time%] inicio > gow\logs\1_instalar.log
winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements >> gow\logs\1_instalar.log 2>&1
echo [git] codigo %errorlevel% >> gow\logs\1_instalar.log
winget install -e --id Python.Python.3.11 --accept-source-agreements --accept-package-agreements >> gow\logs\1_instalar.log 2>&1
echo [python] codigo %errorlevel% >> gow\logs\1_instalar.log
winget install -e --id Microsoft.VisualStudio.2022.BuildTools --accept-source-agreements --accept-package-agreements --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended" >> gow\logs\1_instalar.log 2>&1
echo [vs] codigo %errorlevel% >> gow\logs\1_instalar.log
echo [%date% %time%] fim >> gow\logs\1_instalar.log
echo.
echo Pronto. Feche esta janela e abra uma nova antes do passo 2.
echo Detalhes em gow\logs\1_instalar.log
pause
