@echo off
rem Joga a versao de PC capturando o que o build do Switch precisa:
rem   - os microprogramas da VU1 (dados\vu1\micro): cada um vira codigo nativo no proximo build;
rem   - os modulos do IOP (dados\iop): so na primeira vez.
rem Jogue um pouco de cada area que conseguir (menu, navio, Atenas...): o que nao for capturado roda no interpretador,
rem que e lento no Switch. Feche o jogo quando terminar e rode o passo 2 de novo.
setlocal
cd /d "%~dp0..\.."
set "ROOT=%CD%"
set "DISC=%ROOT%\dados\disc-usa"
set "EXE="
for /r "%ROOT%\build-pc" %%f in (ps2EntryRunner.exe) do if exist "%%f" set "EXE=%%f"
if not defined EXE (echo Versao de PC nao compilada. Rode gow\windows\2_compilar_pc.cmd primeiro. & pause & exit /b 1)
if not exist "%DISC%\SCUS_973.99" (echo Jogo nao extraido em %DISC%. Rode o passo 2 primeiro. & pause & exit /b 1)
if not exist "%DISC%\IOP_MOD\989NOMID.IRX" (
  if not exist "%DISC%\IOP_MOD" mkdir "%DISC%\IOP_MOD"
  copy /y "%DISC%\*.IRX" "%DISC%\IOP_MOD\" >nul
)
if not exist "%DISC%\PART2.PAK" echo AVISO: falta PART2.PAK em %DISC% - o jogo pode travar ao carregar areas da segunda camada do DVD.
if not exist "%ROOT%\dados\vu1\micro" mkdir "%ROOT%\dados\vu1\micro"
if not exist "%ROOT%\gow\logs" mkdir "%ROOT%\gow\logs"

set GOW_VU1_CAPTURA=%ROOT%\dados\vu1\micro
if not exist "%ROOT%\dados\iop\modules.txt" (
  if not exist "%ROOT%\dados\iop" mkdir "%ROOT%\dados\iop"
  set "PS2X_IOP_DUMP_MODULES=%ROOT%\dados\iop"
  echo Capturando tambem os modulos do IOP nesta rodada.
)
rem A apresentacao direta (textura compartilhada) do branch do Switch deixava a janela preta no Windows; a copia
rem pela RAM e um pouco mais lenta, mas aqui so importa ver o jogo para capturar. GOW_DIRETO=1 testa a direta.
if "%GOW_DIRETO%"=="1" (set PS2X_GS_DIRECT_PRESENT=1) else (set PS2X_GS_DIRECT_PRESENT=0)
set PS2X_GS_WORKER=1
set GOW_GS_FINISH_ASINCRONO=1
set GOW_AUDIO_DEVICE=default
set "GOW_MC0=%DISC%\play.mcd"

echo Jogo: %EXE%
echo Capturas em dados\vu1\micro e dados\iop. Feche a janela do jogo para terminar.
cd /d "%DISC%"
"%EXE%" "%DISC%\SCUS_973.99" > "%ROOT%\gow\logs\3_jogar_pc.log" 2>&1
cd /d "%ROOT%"
for /f %%n in ('dir /b "%ROOT%\dados\vu1\micro\*.bin" 2^>nul ^| find /c /v ""') do set "N=%%n"
echo.
echo Microprogramas da VU1 capturados ate agora: %N%
if exist "%ROOT%\dados\iop\modules.txt" (echo Modulos do IOP: capturados.) else (echo Modulos do IOP: NAO capturados - jogue ate o menu principal.)
echo Agora rode gow\windows\2_compilar_pc.cmd de novo.
pause
endlocal
