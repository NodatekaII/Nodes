#!/bin/bash

# Цвета для текста
TERRACOTTA='\033[38;5;208m'
LIGHT_BLUE='\033[38;5;117m'
RED='\033[0;31m'
BOLD='\033[1m'
PURPLE='\033[0;35m'
VIOLET='\033[38;5;93m'
BEIGE='\033[38;5;228m'
NC='\033[0m'
REDL='\033[0;33m'


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
   show_beige '░░░░░█▀▀█░█▀▀█░▀█▀░█▀▀█░█▄░░█░█▀▀▀░▀█▀░░░░░█▄░░█░█▀▀█░█▀▀▄░█▀▀▀░░░░░'
   show_beige '░░░░░█░▄▄░█▀▀█░░█░░█▀▀█░█░█░█░█▀▀▀░░█░░░░░░█░█░█░█░░█░█░░█░█▀▀▀░░░░░'
   show_beige '░░░░░█▄▄█░█░░█░▄█▄░█░░█░█░░▀█░█▄▄▄░░█░░░░░░█░░▀█░█▄▄█░█▄▄▀░█▄▄▄░░░░░'
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
        "1. Установить ноду Gaianet"
        "2. Показать данные для регистрации в проекте"
        "3. Установить скрипт "Автообщение""
        "4. Подключиться к screen-сессии"
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

# Функция для установки зависимостей
install_dependencies() {
    show "Установка необходимых пакетов и зависимостей..."
    sudo apt update && sudo apt upgrade -y
    sudo apt-get install jq
}

# Запрос для пользовательского Node ID
user_nodeid_request() {
    if confirm "Вы переустанавливаете ноду и хотите использовать существующий Node ID?"; then
        read -p "$(show_bold 'Введите ваш Node ID: ') " NODEID_USER
    else
        show "Хорошо. Начинаю установку новой ноды."
    fi
}

# Установка скрипта requests
install_requests() {
    cd ~/gaianet || { show_war "❌ Ошибка: директория ~/gaianet не найдена."; return 1; }
    wget -O requests.sh https://raw.githubusercontent.com/NodatekaII/Nodes/refs/heads/main/Gaianet/requests.sh
    chmod +x requests.sh
    ./requests.sh --install  
}
# Функция для проверки, занят ли порт
is_port_in_use() {
    local port=$1
    netstat -tuln | grep -q ":$port"
}

# Проверка порта
check_port() {
    CONFIG_FILE="$HOME/gaianet/config.json"
    PORT_KEY="llamaedge_port"
    # Найти текущий порт в файле конфигурации
    current_port=$(grep -Po '"'"$PORT_KEY"'":\s*"\K[0-9]+' $CONFIG_FILE)
    if [[ -z "$current_port" ]]; then
         show_war "❌ Не удалось найти ключ '$PORT_KEY' в файле $CONFIG_FILE."
         exit 1
    fi
    echo "Текущий порт: $current_port"
    # Проверить, используется ли текущий порт
    if is_port_in_use "$current_port"; then
        show_war "⚠️ Порт $current_port уже используется."
        # Найти свободный порт
        for new_port in $(seq 8080 9000); do
            if ! is_port_in_use "$new_port"; then
                show "Найден свободный порт: $new_port"
                # Обновить порт в файле конфигурации
                sed -i "s/\"$PORT_KEY\":\s*\"$current_port\"/\"$PORT_KEY\": \"$new_port\"/" $CONFIG_FILE
                show_bold "✅ Порт обновлён на $new_port в $CONFIG_FILE"
                echo ''
                break
            fi
        done
    else
       show "✅ Порт $current_port свободен. Ничего не нужно менять."
    fi
}


# Функция установки ноды
install_node() {
    show "Установка ноды GaiaNet..."
    if curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash; then
        source /root/.bashrc

        show "Инициализация ноды GaiaNet..."
        if gaianet init; then
            show_bold "✅ Инициализация GaiaNet завершена."
            echo ''
        else
            show_war "❌ Ошибка при инициализации GaiaNet."
            return 1
        fi
        if [[ -z "$NODEID_USER" ]]; then
            echo ''
        else
            show "Замена Node ID..."
            sed -i "s/\"address\": \"[^\"]*\"/\"address\": \"$NODEID_USER\"/" ~/gaianet/config.json
            sed -i "s/\"address\": \"[^\"]*\"/\"address\": \"$NODEID_USER\"/" ~/gaianet/nodeid.json    
        fi
        check_port
        # Запуск GaiaNet
        show "Запуск ноды GaiaNet..."
        if gaianet start; then
            show_bold "✅ Нода GaiaNet успешно запущена."
            echo ''
        else
            show_war "❌ Ошибка при запуске GaiaNet."
            return 1
        fi

        # Проверка наличия config.json
        if [ ! -f ~/gaianet/config.json ]; then
            show_war "⚠️ Файл config.json не найден. Убедись, что нода установлена."
            return 1
        fi

        # Извлечение NODEID
        NODEID=$(jq -r '.address' ~/gaianet/config.json)
        if [ -z "$NODEID" ]; then
            show_war "❌ Node ID не найден в config.json."
            return 1
        fi

        # Запуск скрипта автоматического общения
        if confirm "Запустить скрипт автоматического общения с нодой?"; then
            install_requests
        else
            show_war "⚠️ Отмена. Скрипт не запущен."
        fi
    else
        show_war "❌ Ошибка при установке. Проверьте соединение или ссылку."
        return 1
    fi
}

# Данные для регистрации
registration_data() {
   # Проверка наличия config.json
    if [ ! -f ~/gaianet/config.json ]; then
        show_war "⚠️ Файл config.json не найден. Убедись, что нода установлена."
        return 1
    fi

    # Извлечение NODEID
    NODEID=$(jq -r '.address' ~/gaianet/config.json)
    if [ -z "$NODEID" ]; then
        show_war "❌ Node ID не найден в config.json."
        return 1
    fi
    echo ''
    echo -en "${TERRACOTTA}${BOLD}💡 Перейди по ссылке и активируй ноду: ${NC}${LIGHT_BLUE} http://$NODEID.us.gaianet.network${NC}\n"
    show_bold "Node ID: "
    show_beige "$NODEID"
    # Извлечение Device ID
    DEVICEID=$(head -n 1 ~/gaianet/deviceid.txt )
    show_bold "Device ID: "
    show_beige "$DEVICEID"
    echo ''
}

# Удаление ноды
delete() {
    # Подтверждение удаления данных
    if confirm "Удалить директорию и все данные?"; then
        if [ -d ~/gaianet ]; then  
            # Завершение screen-сессии, если она существует
            if screen -list | grep -q "gaia_request"; then
                screen -S gaia_request -X quit
                show "🗑️ Сессия 'gaia_request' успешно завершена."
            else
                show_war "⚠️ Сессия 'gaia_request' не найдена."
            fi
            # Остановка процесса Qdrant
            show "Остановка процесса Qdrant..."
            qdrant_pid=$(ps aux | grep '/root/gaianet/bin/qdrant' | grep -v 'grep' | awk '{print $2}')
            if [[ -n "$qdrant_pid" ]]; then
                show "Процесс Qdrant найден с PID: $qdrant_pid. Завершаем..."
                kill -9 "$qdrant_pid"
                show "🗑️ Процесс Qdrant остановлен."
            else
                show "⚠️ Процесс Qdrant не найден. Возможно, он уже остановлен."
            fi
            # Удаление бинарного файла Qdrant
            show "Удаление бинарного файла Qdrant..."
            if [[ -f "/root/gaianet/bin/qdrant" ]]; then
                rm -f /root/gaianet/bin/qdrant
                show "🗑️ Бинарный файл Qdrant удалён."
            else
                show "⚠️ Бинарный файл Qdrant не найден."
            fi
            # Удаление данных Qdrant
            echo "Удаление данных Qdrant..."
            if [[ -d "/var/lib/qdrant" ]]; then
                rm -rf /var/lib/qdrant
                show "🗑️ Данные Qdrant удалены."
            else
                show "⚠️ Данные Qdrant не найдены."
            fi
            # Удаление конфигурационных файлов
            show "Удаление конфигурационных файлов Qdrant..."
            if [[ -d "/etc/qdrant" ]]; then
                rm -rf /etc/qdrant
                show "🗑️ Конфигурационные файлы Qdrant удалены."
            else
                show "⚠️ Конфигурационные файлы Qdrant не найдены."
            fi
            # Удаление логов
            show "Удаление логов Qdrant..."
            if [[ -d "/var/log/qdrant" ]]; then
                rm -rf /var/log/qdrant
                show "🗑️ Логи Qdrant удалены."
            else
                show "⚠️ Логи Qdrant не найдены."
            fi
            show "🗑️ Операция по остановке и удалению Qdrant завершена."

            # Удаление директории
            rm -rf ~/gaianet
            show_bold "✅ Директория ~/gaianet и все данные успешно удалены."
            echo ''
        else
            show_war "⚠️ Директория ~/gaianet не найдена."
        fi
    else
        show_war "⚠️ Отмена. Данные не удалены."
    fi
}


menu() {
    case $1 in
        1)  user_nodeid_request; install_dependencies; install_node ;;
        2)  registration_data ;;
        3)  install_requests ;;    
        4)  screen -r gaia_request ;;
        9)  delete ;;
        0)  final_message; exit 0 ;;
        *)  show_war "⚠️ Неверный выбор, попробуйте снова." ;;
    esac
}
            

while true; do
    show_menu
    show_bold 'Ваш выбор: '
    read choice
    menu "$choice"
done






