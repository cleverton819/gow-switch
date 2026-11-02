#!/usr/bin/env bash
# Instala no WSL Ubuntu o que o build do Switch precisa: ferramentas de build e o devkitPro (devkitA64, libnx,
# SDL2, Mesa/OpenGL para o Switch). Rodar uma vez:  bash gow/wsl/1_instalar_devkitpro.sh
set -euo pipefail

echo "== Pacotes do Ubuntu (vai pedir sua senha do Linux)"
sudo apt-get update
sudo apt-get install -y build-essential cmake ninja-build git python3 wget ca-certificates

if ! command -v dkp-pacman >/dev/null 2>&1 && [ ! -x /opt/devkitpro/pacman/bin/pacman ]; then
    echo "== Instalando o gerenciador de pacotes do devkitPro"
    tmp="$(mktemp -d)"
    wget -O "$tmp/install-devkitpro-pacman" https://apt.devkitpro.org/install-devkitpro-pacman
    chmod +x "$tmp/install-devkitpro-pacman"
    sudo "$tmp/install-devkitpro-pacman"
    rm -rf "$tmp"
fi

PACMAN=dkp-pacman
command -v dkp-pacman >/dev/null 2>&1 || PACMAN=/opt/devkitpro/pacman/bin/pacman

echo "== Pacotes do Switch"
sudo "$PACMAN" -Sy --noconfirm --needed switch-dev switch-sdl2 switch-mesa switch-glad switch-zlib switch-glfw

# Ubuntu 22.04 traz CMake 3.22; o projeto pede 3.21 ou mais novo
cmake --version | head -1
echo
echo "Pronto. Feche e abra o terminal do Ubuntu (para carregar as variaveis do devkitPro) e rode:"
echo "  bash gow/wsl/2_compilar_switch.sh"
