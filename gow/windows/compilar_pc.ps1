# Gera o C++ do jogo a partir do SCUS_973.99 e compila a versao de PC (ps2EntryRunner.exe).
# A versao de PC e necessaria antes da do Switch: ela gera o codigo da VU1 (a partir das capturas do passo 3) que o
# build do Switch reaproveita, e e com ela que se capturam os modulos do IOP.
# Chamado por gow\windows\2_compilar_pc.cmd, que antes carrega o ambiente do Visual Studio (vcvars64).
# Baseado em scripts\compilar.ps1 de KIexster/god-of-war-recomp (GPLv3), adaptado a este repositorio.
$ErrorActionPreference = 'Stop'

$Repo   = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Gow    = Join-Path $Repo 'gow'
$Dados  = Join-Path $Repo 'dados'          # jogo e capturas (fora do git)
$Disc   = Join-Path $Dados 'disc-usa'
$Gerado = Join-Path $Dados 'gerado'
$Micro  = Join-Path $Dados 'vu1\micro'
$IopDump = Join-Path $Dados 'iop'
$Bld    = Join-Path $Repo 'build-pc'
$Runner = Join-Path $Repo 'ps2xRuntime\src\runner'

function Run([string]$exe, [string[]]$a) {
    Write-Host ">> $exe $($a -join ' ')"
    & $exe @a
    if ($LASTEXITCODE -ne 0) { throw "Falhou ($LASTEXITCODE): $exe" }
}
function Passo([string]$t) { Write-Host ''; Write-Host "==== [$(Get-Date -Format HH:mm:ss)] $t ====" }
function ParaBarras([string]$p) { return $p -replace '\\', '/' }

# Python: o lancador "py" (instalado com o Python do winget) ou "python"
$Py = $null; $PyArgs = @()
if (Get-Command py -ErrorAction SilentlyContinue) { $Py = 'py'; $PyArgs = @('-3') }
elseif (Get-Command python -ErrorAction SilentlyContinue) { $Py = 'python' }
else { throw 'Python nao encontrado. Rode gow\windows\1_instalar.cmd e abra uma janela nova.' }
function RunPy([string[]]$a) { Run $Py ($PyArgs + @('-I') + $a) }

if ($Repo.Length -gt 40) {
    Write-Host "AVISO: a pasta do repositorio tem um caminho longo ($Repo). Se der erro de caminho, clone em C:\gowsw."
}

Passo 'Ferramentas'
Run 'git' @('--version'); Run 'cmake' @('--version'); Run 'ninja' @('--version'); Run $Py ($PyArgs + @('--version'))

Passo 'Disco do jogo'
New-Item -ItemType Directory -Force -Path $Dados | Out-Null
$elf = Join-Path $Disc 'SCUS_973.99'
if (-not (Test-Path -LiteralPath $elf)) {
    $iso = Get-ChildItem -LiteralPath $Dados -Filter '*.iso' -File | Select-Object -First 1
    if (-not $iso) { throw "Coloque a ISO americana do God of War (SCUS-97399) em $Dados e rode de novo." }
    Write-Host "Extraindo $($iso.FullName) para $Disc (uns 8 GB, alguns minutos)"
    RunPy @((Join-Path $Gow 'tools\iso_extract.py'), $iso.FullName, $Disc, '--layout')
}
if (-not (Test-Path -LiteralPath $elf)) { throw "Nao achei $elf depois da extracao. A ISO e a versao americana (SCUS-97399)?" }
Write-Host "ELF: $elf"
# O jogo (modo host) carrega os modulos do IOP como IOP_MOD/<nome>.irx ao lado do ELF, nao da raiz do disco:
# sem esta copia o driver de som (989nomid) nao carrega e o jogo para na tela inicial esperando por ele.
$iopMod = Join-Path $Disc 'IOP_MOD'
New-Item -ItemType Directory -Force -Path $iopMod | Out-Null
foreach ($irx in Get-ChildItem -LiteralPath $Disc -Filter '*.IRX' -File) {
    $dest = Join-Path $iopMod $irx.Name
    if (-not (Test-Path -LiteralPath $dest)) { Copy-Item -LiteralPath $irx.FullName -Destination $dest }
}
Write-Host ("IOP_MOD: {0} modulos" -f (Get-ChildItem -LiteralPath $iopMod -Filter '*.IRX' -File).Count)
foreach ($pak in @('PART1.PAK', 'PART2.PAK')) {
    if (-not (Test-Path -LiteralPath (Join-Path $Disc $pak))) {
        Write-Host "AVISO: falta $pak em $Disc. A ISO deve ser o DVD de duas camadas completo (uns 8 GB);"
        Write-Host "       apague a pasta $Disc e extraia de novo a partir de uma ISO completa."
    }
}

Passo 'Configurando o CMake'
# VU1 compilada: so quando ja existem capturas do passo 3 (sem elas a VU1 roda no interpretador)
$microBins = @()
if (Test-Path -LiteralPath $Micro) { $microBins = @(Get-ChildItem -LiteralPath $Micro -Filter '*.bin' -File) }
if ($microBins.Count -gt 0) {
    Write-Host "VU1: $($microBins.Count) microprogramas capturados em $Micro"
    # o CMake procura a lista de entradas extra em <micro>\..\vu1n_heads.txt
    Copy-Item -LiteralPath (Join-Path $Gow 'tools\vu1\vu1n_heads.txt') -Destination (Join-Path $Dados 'vu1\vu1n_heads.txt') -Force
    $vu1Micro = ParaBarras $Micro
    $vu1Gen   = ParaBarras (Join-Path $Gow 'tools\vu1\generar_vu1.cpp')
    $vu1nGen  = ParaBarras (Join-Path $Gow 'tools\vu1\vu1n_gen.py')
} else {
    Write-Host 'VU1: nenhuma captura ainda (normal na primeira vez; veja o passo 3)'
    $vu1Micro = ''; $vu1Gen = ''; $vu1nGen = ''
}
Run 'cmake' @('-S', $Repo, '-B', $Bld, '-G', 'Ninja', '-DCMAKE_BUILD_TYPE=RelWithDebInfo',
              '-DPS2X_BUILD_STUDIO=OFF', '-DPS2X_BUILD_TEST=OFF', '-DPS2X_BUILD_ANALYZER=OFF', '-DPS2X_ENABLE_SCCACHE=OFF',
              '-DPS2X_ENABLE_RUNTIME_LOGS=OFF', '-DPS2X_ENABLE_AGRESSIVE_LOGS=OFF', '-DPS2X_ENABLE_IOP_RPC_TRACE=OFF',
              "-DPS2X_VU1_MICROCODE_DIR=$vu1Micro", "-DPS2X_VU1_GENERATOR_SOURCE=$vu1Gen", "-DPS2X_VU1N_GEN_OVERRIDE=$vu1nGen",
              '-DPS2X_VU1_PREGENERATED_DIR=')

Passo 'Compilando o recompilador'
Run 'cmake' @('--build', $Bld, '--target', 'ps2_recomp')

Passo 'Gerando C++ a partir do SCUS_973.99'
if (Test-Path -LiteralPath $Gerado) { Remove-Item -LiteralPath $Gerado -Recurse -Force }
New-Item -ItemType Directory -Path $Gerado | Out-Null
$toml = Join-Path $Dados 'recomp.toml'
(Get-Content -LiteralPath (Join-Path $Gow 'config\recomp.template.toml') -Raw) `
    -replace '@ELF@', (ParaBarras $elf) `
    -replace '@MAP@', (ParaBarras (Join-Path $Gow 'config\funcmap.csv')) `
    -replace '@OUT@', ((ParaBarras $Gerado) + '/') |
    Set-Content -LiteralPath $toml -Encoding ASCII
if (-not (Select-String -LiteralPath $toml -SimpleMatch ('input = "' + (ParaBarras $elf) + '"') -Quiet)) {
    throw "O arquivo $toml nao recebeu o caminho do jogo ($elf)"
}
$recompExe = Get-ChildItem -LiteralPath $Bld -Recurse -Filter 'ps2_recomp.exe' | Select-Object -First 1
if (-not $recompExe) { throw 'ps2_recomp.exe nao foi gerado' }
# o relatorio inteiro vai para o log (antes um erro jogava fora a saida e so sobrava "Failed to initialize")
Write-Host ">> $($recompExe.FullName) $toml"
& $recompExe.FullName $toml
if ($LASTEXITCODE -ne 0) { throw "O recompilador falhou ($LASTEXITCODE): veja o relatorio acima (secao Events)" }
Write-Host ("Arquivos gerados: {0}" -f (Get-ChildItem -LiteralPath $Gerado).Count)

Passo 'Copiando o codigo gerado para o runtime'
Get-ChildItem -LiteralPath $Runner -File | Remove-Item -Force
Get-ChildItem -LiteralPath $Gerado -File | Copy-Item -Destination $Runner
Get-ChildItem -LiteralPath (Join-Path $Gow 'overrides') -File | Copy-Item -Destination $Runner

# IOP nativo: so depois que o passo 3 salvou os modulos (sem eles os IRX rodam no interpretador)
if (Test-Path -LiteralPath (Join-Path $IopDump 'modules.txt')) {
    Passo 'Gerando o IOP nativo'
    RunPy @((Join-Path $Gow 'tools\iop\iopn_gen.py'), $IopDump, (Join-Path $Repo 'ps2xIOP\src\native'))
} else {
    Write-Host 'IOP: modulos ainda nao capturados (normal na primeira vez; veja o passo 3)'
}

Passo 'Compilando o jogo'
Run 'cmake' @('-S', $Repo, '-B', $Bld)
Run 'cmake' @('--build', $Bld, '--target', 'ps2EntryRunner')

$exe = Get-ChildItem -LiteralPath $Bld -Recurse -Filter 'ps2EntryRunner.exe' | Select-Object -First 1
if (-not $exe) { throw 'ps2EntryRunner.exe nao foi gerado' }
$vu1Dir = Join-Path $Bld 'ps2xRuntime\vu1_generado'
Passo "OK: $($exe.FullName)"
if (Test-Path -LiteralPath $vu1Dir) { Write-Host "VU1 compilada pronta para o Switch: $vu1Dir" }
else { Write-Host 'Sem VU1 compilada ainda: faca o passo 3 e rode este passo de novo antes do build do Switch.' }
