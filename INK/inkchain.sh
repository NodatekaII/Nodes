#!/bin/bash

# Цвета для текста
TERRACOTTA='\033[38;5;208m'
LIGHT_BLUE='\033[38;5;117m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'
PURPLE='\033[0;35m'

# Функции для форматирования текста
function show() {
    echo -e "${TERRACOTTA}$1${NC}"
}

function show_bold() {
    echo -en "${TERRACOTTA}${BOLD}$1${NC}"
}

function show_blue() {
    echo -e "${LIGHT_BLUE}$1${NC}"
}

function show_war() {
    echo -e "${RED}${BOLD}$1${NC}"
}

function show_purple() {
    echo -e "${PURPLE}$1${NC}"
}

# Логотип команды
show_logotip() {
    bash <(curl -s https://raw.githubusercontent.com/NodatekaII/Basic/refs/heads/main/name.sh)
}

#финальное сообщение
final_message() {
    echo ''
    show_bold "Присоединяйся к Нодатеке, будем ставить ноды вместе!"
    echo ''
    echo -en "${TERRACOTTA}${BOLD}Telegram: ${NC}${LIGHT_BLUE}https://t.me/cryptotesemnikov/778${NC}\n"
    echo -en "${TERRACOTTA}${BOLD}Twitter: ${NC}${LIGHT_BLUE}https://x.com/nodateka${NC}\n"
    echo -e "${TERRACOTTA}${BOLD}YouTube: ${NC}${LIGHT_BLUE}https://www.youtube.com/@CryptoTesemnikov${NC}\n"
}

# Функция для подтверждения действия
confirm() {
    local prompt="$1"
    echo -en "$prompt [y/n, Enter = yes]: "  # Выводим вопрос с цветом
    read choice  # Читаем ввод пользователя
    case "$choice" in
        ""|y|Y|yes|Yes)  # Пустой ввод или "да"
            return 0  # Подтверждение действия
            ;;
        n|N|no|No)  # Любой вариант "нет"
            return 1  # Отказ от действия
            ;;
        *)
            show_war 'Пожалуйста, введите y или n.'
            confirm "$prompt"  # Повторный запрос, если ответ не распознан
            ;;
    esac
}


# Название узла
echo ""
show_purple '░░░░░▀█▀░█▄░░█░█░▄▀░░░█▀▀█░█░░█░█▀▀█░▀█▀░█▄░░█░░░█▄░░█░█▀▀█░█▀▀▄░█▀▀▀░░░░░'
show_purple '░░░░░░█░░█░█░█░█▀▄░░░░█░░░░█▀▀█░█▄▄█░░█░░█░█░█░░░█░█░█░█░░█░█░░█░█▀▀▀░░░░░'
show_purple '░░░░░▄█▄░█░░▀█░█░░█░░░█▄▄█░█░░█░█░░█░▄█▄░█░░▀█░░░█░░▀█░█▄▄█░█▄▄▀░█▄▄▄░░░░░'
show_blue '     script version: v0.2 MINNNET'
echo ""


# Меню с командами
show_menu() {
    clear
    show_logotip
    show_name
    show_bold 'Выберите действие:'
    echo ''
    actions=(
        "1. Установить ноду mainnet"
        "2. Обновить узел до mainnet"
        "3. Просмотр логов ноды"
        "4. Проверка контейнеров"
        "5. Вывод секретных ключей"
        "9. Удаление ноды"
        "0. Выход"
    )
    for action in "${actions[@]}"; do
        show "$action"
    done
}

# Проверка на запуск от имени root
if [ "$EUID" -ne 0 ]; then
  show_war "Пожалуйста, запустите скрипт с правами root."
  exit 1
fi


#Задаем переменные
ink_dir="$HOME/ink/node"

IP=$(curl -4 -s ifconfig.me)
if [ -z "$IP" ]; then
  show_war "Не удалось получить внешний IP адрес."
  exit 1
fi

# Функция для установки зависимостей
install_dependencies() {
    show_bold 'Установить необходимые пакеты и зависимости?'
    if confirm ''; then
        bash <(curl -s https://raw.githubusercontent.com/NodatekaII/Basic/refs/heads/main/docker.sh)
        sudo apt install jq net-tools
    else
        show_war 'Отменено.'
    fi
}
#Клонируем ррепозиторий
clone_rep() {
    show 'Клонирование репозитория Ink node..'
    if [ -d "$ink_dir" ]; then
        show "Репозиторий уже скачан. Пропуск клонирования."
    else
        git clone https://github.com/inkonchain/node.git "$ink_dir" || {
            show_war 'Ошибка: не удалось клонировать репозиторий.'
            exit 0
        }
    fi
}
#Создаем файл
create_env_file() {
    show "Добавление переменных в .env..."
    cat > "$ink_dir/.env" <<EOL
# ("ink-mainnet", "ink-sepolia", etc.)
NETWORK_NAME=ink-mainnet

# ("full" or "archive"), note that "archive" is 10x bigger
NODE_TYPE=full

# Вставь сюда свои OP_NODE__RPC_ENDPOINT и OP_NODE__L1_BEACON
OP_NODE__RPC_ENDPOINT=https://ethereum-rpc.publicnode.com
OP_NODE__L1_BEACON=https://eth-beacon-chain.drpc.org/rest/

# alchemy -Alchemy, quicknode -Quicknode, erigon -Erigon, basic -Other providers
OP_NODE__RPC_TYPE=basic

# https://rpc-gel-sepolia.inkonchain.com for ink-sepolia or https://rpc-gel.inkonchain.com for ink-mainnet)
HEALTHCHECK__REFERENCE_RPC_PROVIDER=https://rpc-gel.inkonchain.com

###############################################################################
#                                ↓ OPTIONAL ↓                                 #
###############################################################################

# snap - Snap Sync (Default), full - Full Sync (For archive node)
OP_GETH__SYNCMODE=snap

# Feel free to customize your image tag if you want, uses "latest" by default
# See here for all available images: https://hub.docker.com/u/ethereumoptimism
IMAGE_TAG__DTL=
IMAGE_TAG__HEALTCHECK=
IMAGE_TAG__PROMETHEUS=
IMAGE_TAG__GRAFANA=
IMAGE_TAG__INFLUXDB=
IMAGE_TAG__OP_GETH=
IMAGE_TAG__OP_NODE=

# Exposed server ports (must be unique)
# See docker-compose.yml for default values
PORT__DTL=33391
PORT__HEALTHCHECK_METRICS=7301
PORT__PROMETHEUS=9390
PORT__GRAFANA=3301
PORT__INFLUXDB=8386
PORT__TORRENT_UI=33396
PORT__TORRENT=33398
PORT__OP_GETH_HTTP=9393
PORT__OP_GETH_WS=33394
PORT__OP_GETH_P2P=33393
PORT__OP_NODE_P2P=9303
PORT__OP_NODE_HTTP=9345
EOL
}

# Функция установки ноды
install_node() {
    mkdir -p ~/ink && cd ~/ink
    clone_rep

    show "Переход в директорию узла..."
    cd "$ink_dir" || {
        show_war "Ошибка: директория не найдена!"
    }
   
   create_env_file

    # Запуск Docker Compose
    show "Запуск ноды..."
    docker compose up -d || {
        show "Перезапуск Docker Compose..."
        docker compose down && docker compose up -d || {
            show_war "Ошибка при повторном запуске Docker Compose!"
            exit 1
        }
    }
    show_bold "Установка и запуск выполнены успешно!"
    echo ""  # Пустая строка для разделения между контейнерами
    echo -en "${TERRACOTTA}${BOLD}Проверь статус по ссылке: ${NC}${LIGHT_BLUE} http://$IP:3301/${NC}\n"
    echo ""  # Пустая строка для разделения между контейнерами
}


# Обновление узла до mainnet
update_mainnet() {
    show "Обновление узла до mainnet..."
    cd "$ink_dir" && docker compose down
    rm -rf "$ink_dir/geth/chaindata" && mkdir -p "$ink_dir/geth/chaindata"
    git stash && git pull

    create_env_file

    show "Запуск Docker Compose..."
    docker compose up -d --build || {
        show_war "Ошибка при запуске Docker Compose!"
        exit 1
    }
    show_bold "Узел успешно обновлён до mainnet!"
    echo ""  # Пустая строка для разделения между контейнерами
    echo -en "${TERRACOTTA}${BOLD}Проверь статус ноды по ссылке: ${NC}${LIGHT_BLUE} http://$IP:3301/${NC}\n"
    echo ""  # Пустая строка для разделения между контейнерами
}

get_private_key() {
    echo ''
    show_bold "JWT-token: "
    docker exec -it node-op-geth-1 cat /shared/jwt.txt
    show_bold "Secret key: "
    docker exec -it node-op-geth-1 cat geth/geth/nodekey
    echo ''
}

# Удаление ноды
delete() {
    if [ -d "$ink_dir" ] && docker ps | grep -q "node-op-geth-1"; then
        show_war "Нода активна! Остановите её перед удалением."
        return 1
    fi
    
    show "Остановка и удаление контейнеров"
    
    # Останавливаем контейнеры и проверяем существование директории
    if [ -d "$ink_dir" ]; then
        cd "$ink_dir" && docker compose down
    else
        show_war "Директория $ink_dir не найдена. Контейнеры не остановлены."
    fi
    # Подтверждение удаления данных
    if confirm "Удалить директорию и все данные?"; then
        if [ -d ~/ink ]; then
            cd ~ && rm -rf ~/ink
            show_bold "Успешно удалено."
        else
            show_war "Директория ~/ink не найдена."
        fi
    else
        show_war "Отмена. Не удалено."
    fi
}

menu() {
    case $1 in
        1)  install_dependencies; install_node ;;
        2)  update_mainnet ;;
        3)  cd "$ink_dir" && docker compose logs -f --tail 20 ;;
        4)  [ -d "$ink_dir" ] && cd "$ink_dir" && docker compose ps -a || show_war "Директория $ink_dir не найдена." ;;
        5)  get_private_key ;;
        9)  delete ;;
        0)  final_message; exit 0 ;;
        *)  show_war "Неверный выбор, попробуйте снова." ;;
    esac
}
            

while true; do
    show_menu
    show_bold 'Ваш выбор:'
    read choice
    menu "$choice"
done
