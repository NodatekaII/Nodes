#!/bin/bash

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

# Цвета для текста
TERRACOTTA='\033[38;5;208m'
LIGHT_BLUE='\033[38;5;117m'
RED='\033[0;31m'
BOLD='\033[1m'
PURPLE='\033[0;35m'
VIOLET='\033[38;5;93m'
BEIGE='\033[38;5;228m'
GOLD='\033[38;5;220m'
NC='\033[0m'


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

function show_violet() {
    echo -e "${VIOLET}$1${NC}"
}

function show_beige() {
    echo -e "${BEIGE}$1${NC}"
}

function show_gold() {
    echo -e "${GOLD}$1${NC}"
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
    show_bold "❓ $prompt [y/n, Enter = yes]: "  # Выводим вопрос с цветом
    read choice  # Читаем ввод пользователя
    case "$choice" in
        ""|y|Y|yes|Yes)  # Пустой ввод или "да"
            return 0  # Подтверждение действия
            ;;
        n|N|no|No)  # Любой вариант "нет"
            return 1  # Отказ от действия
            ;;
        *)
            show_war '⚠️ Пожалуйста, введите y или n.'
            confirm "$prompt"  # Повторный запрос, если ответ не распознан
            ;;
    esac
}


# Название узла
show_name() {
   echo ""
   show_gold '░░░░░░░█▀▀█░▀█▀░▀█▀░█░░█░█▀▀█░█░░░░░░░░░█▄░░█░█▀▀█░█▀▀▄░█▀▀▀░░░░░░░'
   show_gold '░░░░░░░█▄▄▀░░█░░░█░░█░░█░█▀▀█░█░░░░░░░░░█░█░█░█░░█░█░░█░█▀▀▀░░░░░░░'
   show_gold '░░░░░░░█░░█░▄█▄░░█░░▀▄▄▀░█░░█░█▄▄█░░░░░░█░░▀█░█▄▄█░█▄▄▀░█▄▄▄░░░░░░░'
   #show_blue '     script version: v0.2 MAINNNET'
   echo ""
}

# Меню с командами
show_menu() {
    show_logotip
    show_name
    show_bold 'Выберите действие: '
    echo ''
    actions=(
        "1. Установить ноду Ritual"
        "2. Смена базовых настроек"
        "3. Замена RPC"
        "4. Просмотр состояния контейнеров"
        "5. Просмотр логов ноды"
        "6. Перезагрузка контейнеров (отчистка диска)"
        "9. Удаление ноды"
        "0. Выход"

    )
    for action in "${actions[@]}"; do
        show "$action"
    done
}

# Проверка на запуск от имени root
if [ "$EUID" -ne 0 ]; then
  show_war "⚠️ Пожалуйста, запустите скрипт с правами root."
  exit 1
fi



#Установка зависимостей
install_dependencies() {
    show 'Установка необходимых пакетов и зависимостей...'
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y make build-essential unzip lz4 gcc git jq ncdu tmux \
    cmake clang pkg-config libssl-dev python3-pip protobuf-compiler bc curl screen
    show "Установка Docker и Docker Compose..."
    bash <(curl -s https://raw.githubusercontent.com/NodatekaII/Basic/refs/heads/main/docker.sh)
    show "Скачивание необходимого образа..."
    docker pull ritualnetwork/hello-world-infernet:latest
}


# Переменные для путей
CONFIG_PATH="/root/infernet-container-starter/deploy/config.json"
HELLO_CONFIG_PATH="/root/infernet-container-starter/projects/hello-world/container/config.json"
DEPLOY_SCRIPT_PATH="/root/infernet-container-starter/projects/hello-world/contracts/script/Deploy.s.sol"
MAKEFILE_PATH="/root/infernet-container-starter/projects/hello-world/contracts/Makefile"
DOCKER_COMPOSE_PATH="/root/infernet-container-starter/deploy/docker-compose.yaml"
PORTS=("4000" "6379" "24224" "8545" "3000")
#foundryup="/root/.foundry/bin/foundryup"
#FORGE_PATH="/root/.foundry/bin/forge"
export PATH=$PATH:/root/.foundry/bin

# Проверка, занят ли порт
is_port_in_use() {
    local port=$1
    netstat -tuln | grep -q ":$port"
}

# Поиск первого свободного порта
find_free_port() {
    local start_port=$1
    for port in $(seq $start_port 65535); do
        if ! is_port_in_use "$port"; then
            echo "$port"
            return
        fi
    done
    show_war "❌ Не найден свободный порт."
    exit 1
}

# Общая функция для проверки и замены портов
check_and_replace_port() {
    local current_port=$1
    local start_search_port=$2
    local config_file=$3
    local docker_compose_file=$4
    local key_pattern=$5

    if is_port_in_use "$current_port"; then
        show "⚠️ Порт $current_port занят. Поиск свободного порта..."
        free_port=$(find_free_port "$start_search_port")
        show "✅ Найден свободный порт: $free_port"

        # Замена порта в конфигурационном файле
        if [[ -n "$config_file" && -n "$key_pattern" ]]; then
            sed -i "s|$key_pattern $current_port|$key_pattern $free_port|" "$config_file"
        fi

        # Замена порта в docker-compose.yaml
        if [[ -n "$docker_compose_file" ]]; then
            sed -i "s|$current_port:|$free_port:|" "$docker_compose_file"
            
        fi
    else
        show "✅ Порт $current_port свободен."
    fi
}




# Функция для клонирования репозитория
clone_repository() {
    local repo_url="https://github.com/ritual-net/infernet-container-starter"
    local destination="/root/infernet-container-starter"  # Каталог в корневой директории

    # Проверяем, существует ли папка и не является ли она пустой
    if [[ -d "$destination" && -n "$(ls -A "$destination")" ]]; then
        show_war "⚠️ Каталог '$destination' уже существует и не пуст."
        if confirm "Удалить существующий каталог и клонировать заново?"; then
            show "Удаление существующего каталога и клонирование..."
            sudo rm -rf "$destination"
            git clone "$repo_url" "$destination"
        else
            show_war "⚠️ Клонирование пропущено."
        fi
    else
        show "Клонирование репозитория infernet-container-starter..."
        git clone "$repo_url" "$destination"
    fi

    # Переход в каталог
    cd "$destination" || { show_war "❌ Ошибка: Не удалось перейти в каталог $destination"; exit 1; }
}

# Функция для изменений настроек
change_settings() {
    # Получение данных
    read -p "$(show_bold 'Введите значение sleep [3]: ') " SLEEP
    SLEEP=${SLEEP:-3}
    read -p "$(show_bold 'Введите значение trail_head_blocks [1]: ') " TRAIL_HEAD_BLOCKS
    TRAIL_HEAD_BLOCKS=${TRAIL_HEAD_BLOCKS:-1}
    read -p "$(show_bold 'Введите значение batch_size [1800]: ') " BATCH_SIZE
    BATCH_SIZE=${BATCH_SIZE:-1800}
    read -p "$(show_bold 'Введите значение starting_sub_id [205000]: ') " STARTING_SUB_ID
    STARTING_SUB_ID=${STARTING_SUB_ID:-205000}

    # Внесение изменений
    sed -i "s|\"sleep\":.*|\"sleep\": $SLEEP,|" "$HELLO_CONFIG_PATH"
    sed -i "s|\"batch_size\":.*|\"batch_size\": $BATCH_SIZE,|" "$HELLO_CONFIG_PATH"
    sed -i "s|\"starting_sub_id\":.*|\"starting_sub_id\": $STARTING_SUB_ID,|" "$HELLO_CONFIG_PATH"
    sed -i "s|\"trail_head_blocks\":.*|\"trail_head_blocks\": $TRAIL_HEAD_BLOCKS,|" "$HELLO_CONFIG_PATH"

}


# Функция для настройки конфигурационных файлов
configure_files() {
        show "Настройка файлов конфигурации..."

        # Резервное копирование файлов
        cp "$HELLO_CONFIG_PATH" "${HELLO_CONFIG_PATH}.bak"
        cp "$DEPLOY_SCRIPT_PATH" "${DEPLOY_SCRIPT_PATH}.bak"
        cp "$MAKEFILE_PATH" "${MAKEFILE_PATH}.bak"
        cp "$DOCKER_COMPOSE_PATH" "${DOCKER_COMPOSE_PATH}.bak"

        # Параметры с пользовательским вводом
        read -p "$(show_bold 'Введите ваш private_key (c 0x): ') " PRIVATE_KEY
        read -p "$(show_bold 'Введите адрес RPC [https://mainnet.base.org]: ') " RPC_URL
        RPC_URL=${RPC_URL:-https://mainnet.base.org}
        change_settings
        check_and_replace_port 3000 3001 "$HELLO_CONFIG_PATH" "" "\""
        check_and_replace_port 4000 4001 "$HELLO_CONFIG_PATH" "$DOCKER_COMPOSE_PATH" "4000,"
        check_and_replace_port 6379 6380 "$HELLO_CONFIG_PATH" "" "\"port\":"
        check_and_replace_port 8545 8546 "" "$DOCKER_COMPOSE_PATH" ""
        
        sed -i "s|\"registry_address\":.*|\"registry_address\": \"0x3B1554f346DFe5c482Bb4BA31b880c1C18412170\",|" "$HELLO_CONFIG_PATH"
        sed -i "s|\"private_key\":.*|\"private_key\": \"$PRIVATE_KEY\",|" "$HELLO_CONFIG_PATH"
        sed -i "s|\"rpc_url\":.*|\"rpc_url\": \"$RPC_URL\",|" "$HELLO_CONFIG_PATH"

        # Изменения в deploy-скрипте и Makefile
        sed -i "s|address registry =.*|address registry = 0x3B1554f346DFe5c482Bb4BA31b880c1C18412170;|" "$DEPLOY_SCRIPT_PATH"
        sed -i "s|sender :=.*|sender := $PRIVATE_KEY|" "$MAKEFILE_PATH"
        sed -i "s|RPC_URL :=.*|RPC_URL := $RPC_URL|" "$MAKEFILE_PATH"

        # Изменение порта в docker-compose.yaml
       
        sed -i "s|ritualnetwork/infernet-node:1.3.1|ritualnetwork/infernet-node:1.4.0|" "$DOCKER_COMPOSE_PATH"    

        show_bold "✅ Настройка файлов завершена."
        echo ''

}

# Функция для запуска screen сессии
start_screen_session() {
        if screen -list | grep -q "ritual"; then
            show_war "⚠️ Найдена предыдущая сессия 'ritual'. Удаляем..."
            screen -S ritual -X quit
            show "Запуск screen сессии 'ritual'..."
            screen -S ritual -d -m bash -c "project=hello-world make deploy-container; bash"
            show_bold "✅ Screen сессия ritual успешно запущена."
            echo ''
        fi
}

# Перезапуск проекта
restart_node() {
        show "Перезапуск контейнеров..."
        docker compose -f $DOCKER_COMPOSE_PATH down
        docker compose -f $DOCKER_COMPOSE_PATH up -d 
}

# Функция для выполнения foundryup
run_foundryup() {
    # Проверяем, установлен ли Foundry
    if ! command -v foundryup &> /dev/null; then
        show_war "⚠️ Foundry не установлен. Сначала выполните установку."
        return 1
    fi

    # Проверяем, добавлен ли путь Foundry в .bashrc
    if ! grep -q 'foundryup' ~/.bashrc; then
        show_war "⚠️ Путь до Foundry не найден в .bashrc. Добавление..."
        echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> ~/.bashrc
        source ~/.bashrc
    fi

    show "Запуск foundryup..."
    foundryup
}

# Функция для установки Foundry
install_foundry() {
    # Проверяем, установлен ли Foundry
    if command -v foundryup &> /dev/null; then
        show "Foundry уже установлен."
    else
        show "Установка Foundry..."
        curl -L https://foundry.paradigm.xyz | bash
    fi

    # Выполняем foundryup
    run_foundryup
}


# Функция для установки зависимостей проекта
install_project_dependencies() {
        show "Установка зависимостей для hello-world проекта..."
        cd /root/infernet-container-starter/projects/hello-world/contracts || exit
        forge install --no-commit foundry-rs/forge-std || { echo "⚠️ Ошибка при установке зависимости forge-std. Устраняем..."; rm -rf lib/forge-std && forge install --no-commit foundry-rs/forge-std; }
        forge install --no-commit ritual-net/infernet-sdk || { echo "⚠️ Ошибка при установке зависимости infernet-sdk. Устраняем..."; rm -rf lib/infernet-sdk && forge install --no-commit ritual-net/infernet-sdk; }
}

# Функция для автоматической вставки адреса контракта
call_contract() {
    show "Развертывание контракта..."
    cd /root/infernet-container-starter || exit

    # Развёртываем контракт и извлекаем адрес
    DEPLOY_OUTPUT=$(project=hello-world make deploy-contracts)
    CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP '(?<=Contract deployed at: )0x[a-fA-F0-9]{40}')

    if [[ -z "$CONTRACT_ADDRESS" ]]; then
        show_war "❌ Ошибка: Не удалось извлечь адрес контракта."
        return 1
    fi

    show "Адрес контракта: $CONTRACT_ADDRESS"

    # Файл для замены
    local contract_file="/root/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol"
    if [[ ! -f "$contract_file" ]]; then
        show_war "❌ Файл $contract_file не найден."
        return 1
    fi

    # Заменяем адрес контракта в файле
    show "Запись адреса контракта в файл $contract_file..."
    if sed -i "s|SaysGM(.*)|SaysGM($CONTRACT_ADDRESS)|" "$contract_file"; then
        show_bold "✅ Адрес контракта успешно записан."
        echo ''
    else
        show_war "❌ Ошибка при вставке адреса контракта."
        return 1
    fi

    # Вызываем контракт
    show "Вызов контракта..."
    if project=hello-world make call-contract; then
        show_bold "✅ Контракт успешно вызван."
        echo ""
    else
        show_war "❌ Ошибка при вызове контракта."
        return 1
    fi
}
# Функция для замены RPC URL
replace_rpc_url() {
    if confirm "Заменить RPC URL?"; then
        read -p "$(show_bold 'Введите новый RPC URL [https://mainnet.base.org]: ') " NEW_RPC_URL
        NEW_RPC_URL=${NEW_RPC_URL:-https://mainnet.base.org}

        CONFIG_PATHS=(
            "/root/infernet-container-starter/projects/hello-world/container/config.json"
            "/root/infernet-container-starter/deploy/config.json"
            "/root/infernet-container-starter/projects/hello-world/contracts/Makefile"
        )

        # Переменная для отслеживания найденных файлов
        files_found=false

        for config_path in "${CONFIG_PATHS[@]}"; do
            if [[ -f "$config_path" ]]; then
                sed -i "s|\"rpc_url\": \".*\"|\"rpc_url\": \"$NEW_RPC_URL\"|g" "$config_path"
                show "RPC URL заменен в $config_path"
                files_found=true  # Устанавливаем флаг, если файл найден
            else
                show_war "⚠️ Файл $config_path не найден, пропуск..."
            fi
        done

        # Если не найдено ни одного файла, выводим сообщение
        if ! $files_found; then
            show_war "❌ Не удалось найти ни одного конфигурационного файла для замены RPC URL."
            return  # Завершаем выполнение функции
        fi
        restart_node
        show_bold "✅ Контейнеры перезапущены после замены RPC URL."
        echo ''
    else
        show "⚠️ Замена RPC URL отменена."
    fi
}

# Функция для удаления ноды
delete_node() {
    if confirm "Удалить ноду и очистить файлы?"; then
        cd ~
        show "Остановка и удаление контейнеров..."
        docker compose -f $DOCKER_COMPOSE_PATH down

        # Завершение screen сессии
        if screen -list | grep -q "ritual"; then
            show "Завершение screen сессии 'ritual'..."
            screen -S ritual -X quit
        fi

        show "Удаление директории проекта..."
        rm -rf ~/infernet-container-starter
        
        show_bold "✅ Нода удалена и файлы очищены."
        echo ''
    else
        show "⚠️ Удаление ноды отменено."
    fi
}


menu() {
    # Проверка аргумента меню
    if [[ -z "$1" ]]; then
        show_war "⚠️ Пожалуйста, выберите пункт меню."
        return
    fi

    case $1 in
        1)  
            # Установка ноды
            install_dependencies
            clone_repository
            configure_files
            start_screen_session
            install_foundry
            install_project_dependencies
            call_contract
            ;;
        2)  
            # Изменение настроек и перезапуск ноды
            change_settings
            cp "$HELLO_CONFIG_PATH" "$CONFIG_PATH"
            restart_node
            ;;
        3)  
            # Замена RPC URL
            replace_rpc_url
            ;;
        4)  
            # Просмотр запущенных контейнеров
            docker ps -a | grep infernet
            ;;
        5)  
            # Просмотр логов ноды
            docker logs -f --tail 20 infernet-node
            ;;
        6)  
            # Перезапуск контейнеров
            show "Перезапуск контейнеров..."
            restart_node
            ;;
        9)  
            # Удаление ноды с подтверждением
            delete_node
            ;;
        0)  
            # Выход с финальным сообщением
            final_message
            exit 0
            ;;
        *)  
            # Обработка неверного ввода
            show_war "⚠️ Неверный выбор, попробуйте снова."
            ;;
    esac
}
            

while true; do
    show_menu
    show_bold 'Ваш выбор: '
    read choice
    menu "$choice"
done
