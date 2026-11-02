#!/usr/bin/env bash
# Compila o God of War para o Switch (NRO) a partir deste repositorio, no WSL Ubuntu.
# Antes: a versao de PC compilada no Windows com as capturas (gow/windows, passos 2 e 3), porque o codigo da VU1 e o
# do IOP gerados la sao reaproveitados aqui.
#   bash gow/wsl/2_compilar_switch.sh          (CLEAN=1 para comecar do zero)
# Resultado: sd/switch/gow/gow.nro e sd/switch/gow/env.txt, para copiar ao cartao SD junto com dados/disc-usa.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VU1_PREGEN="${VU1_PREGEN:-$REPO/build-pc/ps2xRuntime}"
# A pasta do build fica no disco do Linux (~), muito mais rapido que em /mnt/c
export BUILD_DIR="${BUILD_DIR:-$HOME/gow-switch-build}"
export VU1_PREGEN

[ -f "$REPO/ps2xRuntime/src/runner/gow_overrides.cpp" ] \
    || { echo "erro: codigo do jogo nao gerado. Rode gow\\windows\\2_compilar_pc.cmd no Windows primeiro." >&2; exit 1; }
if [ ! -d "$VU1_PREGEN/vu1_generado" ]; then
    echo "AVISO: sem VU1 compilada em $VU1_PREGEN." >&2
    echo "       Sem ela o jogo fica MUITO lento no Switch. Faca o passo 3 (captura) e o passo 2 de novo no Windows." >&2
    read -r -p "Continuar mesmo assim? [s/N] " resp
    [ "${resp:-n}" = "s" ] || exit 1
fi
if ! ls "$REPO"/ps2xIOP/src/native/iopn_registry.cpp >/dev/null 2>&1; then
    echo "AVISO: sem IOP nativo (os carregamentos ficam mais lentos). Veja o passo 3 no Windows." >&2
fi

# o repositorio esta em /mnt/c (dono: usuario do Windows); sem isto o git recusa operar nele
git config --global --get-all safe.directory 2>/dev/null | grep -qxF "$REPO" || git config --global --add safe.directory "$REPO"

echo "== Compilando (a primeira vez leva ~40 min ou mais; se o WSL ficar sem memoria, rode com JOBS=4)"
bash "$REPO/switch/build.sh"

NRO="$(find "$BUILD_DIR" -name '*.nro' -print -quit)"
[ -n "$NRO" ] || { echo "erro: o NRO nao foi gerado" >&2; exit 1; }

SD="$REPO/sd/switch/gow"
mkdir -p "$SD"
cp "$NRO" "$SD/gow.nro"
if [ ! -f "$SD/env.txt" ]; then
    cat > "$SD/env.txt" <<'EOF'
# Configuracoes do God of War no Switch: uma por linha, CHAVE=VALOR (# comeca um comentario)
# Linhas de desempenho no log.txt
GOW_PERF_DIAG=1
# 1 = reaproveita o quadro quando o jogo so alterna os dois buffers da tela (otimizacao nova); 0 = original
GOW_GS_PRESENT_ALT=1
# Limite opcional de recomposicoes da tela por segundo (0 = sem limite)
#GOW_GS_PRESENT_MAX_HZ=30
EOF
fi
echo
echo "Pronto: $SD/gow.nro"
echo "Copie para o cartao SD (exFAT):"
echo "  sd/switch/gow/gow.nro e env.txt  ->  sdmc:/switch/gow/"
echo "  dados/disc-usa (a pasta inteira) ->  sdmc:/switch/gow/disc-usa/"
echo "Abra pelo Homebrew Menu segurando R sobre um jogo (modo title takeover; o modo applet nao tem memoria suficiente)."
