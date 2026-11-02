# God of War (PS2) no Switch: como compilar

Port nativo do God of War americano (`SCUS-97399`) para o Nintendo Switch, por recompilação estática. O código
vem do port de [Waffle565](https://github.com/Waffle565/God-Of-War-Native-Port) (branch `switch`, versão v15),
com a configuração da versão americana e os scripts de build de
[KIexster](https://github.com/KIexster/god-of-war-recomp), ambos GPLv3.

> **Nada do jogo está neste repositório, e nunca deve ser enviado para ele.** Você precisa da sua própria ISO
> americana. A pasta `dados/` (jogo, capturas, código gerado) fica fora do git.

## O que você precisa
- Windows 10/11 com uns **60 GB livres** e de preferência 16 GB de RAM.
- **WSL com Ubuntu** (no PowerShell como administrador: `wsl --install -d Ubuntu`, depois reinicie).
- A ISO do **God of War (USA)**, `SCUS-97399`.
- Switch com **Atmosphère** e cartão SD em **exFAT** (os arquivos `PART1.PAK`/`PART2.PAK` têm 4 GB cada).

## Passo a passo

### 0. Baixar o repositório (uma vez)
Use um caminho curto, sem acentos nem espaços (o Windows tem limite de 260 caracteres):
```bat
git clone https://github.com/cleverton819/gow-switch C:\gowsw
mkdir C:\gowsw\dados
```
Copie a ISO para `C:\gowsw\dados\` (qualquer nome terminado em `.iso`).

### 1. Instalar as ferramentas do Windows (uma vez)
Dê dois cliques em `gow\windows\1_instalar.cmd`. Ele instala Git, Python e o compilador C++ da Microsoft
(15 a 30 minutos). Depois feche e abra o Explorer/terminal.

### 2. Compilar a versão de PC
Dê dois cliques em `gow\windows\2_compilar_pc.cmd` (20 a 40 minutos na primeira vez). Ele extrai a ISO para
`dados\disc-usa`, traduz o código do jogo para C++ e compila a versão de PC. Se der erro, mande o arquivo
`gow\logs\2_compilar_pc.log`.

### 3. Jogar no PC para capturar (importante para o desempenho no Switch)
Dê dois cliques em `gow\windows\3_jogar_pc_captura.cmd` e jogue: passe pelo menu, comece um jogo novo e jogue
o navio. Se tiver saves, visite outras áreas. Ele salva:
- os **microprogramas da VU1** (o processador de geometria do PS2): cada um vira código nativo no próximo
  build. O que não for capturado roda num interpretador, que é **muito lento no Switch**;
- os **módulos do IOP** (som, memory card, disco), só na primeira vez.

Feche o jogo e rode o **passo 2 de novo**: agora ele compila também a VU1 e o IOP nativos. Pode repetir os
passos 3 e 2 sempre que quiser capturar áreas novas.

### 4. Instalar o devkitPro no WSL (uma vez)
Abra o **Ubuntu** e rode:
```sh
cd /mnt/c/gowsw
bash gow/wsl/1_instalar_devkitpro.sh
```
Depois feche e abra o Ubuntu de novo.

### 5. Compilar para o Switch
No Ubuntu:
```sh
cd /mnt/c/gowsw
bash gow/wsl/2_compilar_switch.sh
```
A primeira vez leva uns 40 minutos ou mais. Se o WSL ficar sem memória (o compilador "morre" com
`Killed`), rode com menos tarefas em paralelo: `JOBS=4 bash gow/wsl/2_compilar_switch.sh`.

### 6. Copiar para o cartão SD
```
C:\gowsw\sd\switch\gow\gow.nro   ->  SD:\switch\gow\gow.nro
C:\gowsw\sd\switch\gow\env.txt   ->  SD:\switch\gow\env.txt
C:\gowsw\dados\disc-usa\         ->  SD:\switch\gow\disc-usa\   (a pasta inteira, ~8 GB)
```

### 7. Jogar
Abra o Homebrew Menu **segurando R sobre um jogo** (modo *title takeover*). Pelo álbum (modo applet) não há
memória suficiente. O jogo escreve `SD:\switch\gow\log.txt`; mande esse arquivo depois de testar.

## Configurações (`SD:\switch\gow\env.txt`)
| Linha | O que faz |
|---|---|
| `GOW_PERF_DIAG=1` | Linhas de desempenho no `log.txt` (deixe ligado nos testes) |
| `GOW_GS_PRESENT_ALT=1` / `0` | Liga/desliga a otimização nova de apresentação da tela (padrão: ligada) |
| `GOW_GS_PRESENT_MAX_HZ=30` | Limita quantas vezes por segundo a tela é recomposta (padrão: sem limite) |
| `GOW_CPU_MHZ=1785` | Clock da CPU (padrão 1785, o boost da própria Nintendo; `0` não mexe) |

Mais detalhes técnicos do port no Switch: `docs/switch.md` do branch `port`.

## Atualizar o código
Quando houver mudanças novas no repositório:
```bat
cd C:\gowsw
git pull
```
Depois rode o passo 2 (no Windows) e o passo 5 (no Ubuntu) de novo; os dois só recompilam o que mudou.
