#!/bin/bash

# Цвета для текста
TERRACOTTA='\033[38;5;208m'
LIGHT_BLUE='\033[38;5;117m'
RED='\033[0;31m'
BOLD='\033[1m'
PURPLE='\033[0;35m'
VIOLET='\033[38;5;93m'
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
show_name() {
   echo ""
   show_violet '░░░░░▀█▀░█▄░░█░█░▄▀░░░█▀▀█░█░░█░█▀▀█░▀█▀░█▄░░█░░░█▄░░█░█▀▀█░█▀▀▄░█▀▀▀░░░░░'
   show_violet '░░░░░░█░░█░█░█░█▀▄░░░░█░░░░█▀▀█░█▄▄█░░█░░█░█░█░░░█░█░█░█░░█░█░░█░█▀▀▀░░░░░'
   show_violet '░░░░░▄█▄░█░░▀█░█░░█░░░█▄▄█░█░░█░█░░█░▄█▄░█░░▀█░░░█░░▀█░█▄▄█░█▄▄▀░█▄▄▄░░░░░'
   show_blue '     script version: v0.2 MAINNNET'
   echo ""
}

# Меню с командами
show_menu() {
    show_logotip
    show_name
    show_bold 'Выберите действие:'
    echo ''
    actions=(
        "1. Установить ноду Gaianet"
        "2. Установить скрипт "Автообщения""
        "3. Показать данные для регистрации в проекте"
        "4. "
        "5. "
        "6. "
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

# Функция для установки зависимостей
install_dependencies() {
    show "Установить необходимые пакеты и зависимости?"
    sudo apt update && sudo apt upgrade -y
    sudo apt-get install jq
}

# Установка скрипта requests
install_requests() {
    cd ~/gaianet || { show_war "Ошибка: директория ~/gaianet не найдена."; return 1; }
    wget https://raw.githubusercontent.com/NodatekaII/Nodes/refs/heads/main/Gaianet/requests.sh
    chmod +x requests.sh
    ./requests.sh --install
    
}


# Функция установки ноды
install_node() {
    show "Установка ноды GaiaNet..."
    if curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash; then
       source /root/.bashrc
    show "Инициализация ноды GaiaNet..."
    if gaianet init; then
        show_bold "Инициализация GaiaNet завершена."
    else
        show_war "Ошибка при инициализации GaiaNet."
        return 1
    fi
    else
       show_war "Ошибка при установке. Проверьте соединение или ссылку."
       return 1
fi


    # Запуск GaiaNet
    show "Запуск ноды GaiaNet..."
    if gaianet start; then
        show_bold "Нода GaiaNet успешно запущена."
    else
        show_war "Ошибка при запуске GaiaNet."
        return 1
    fi
    
    # Запуск скрипта
    if confirm "Запустить скрипт автоматического общения с нодой?"; then
        install_requests
    else
        show_war "Отмена. Скрипт не запущен."
    fi
}

# Удаление ноды
delete() {
    # Подтверждение удаления данных
    if confirm "Удалить директорию и все данные?"; then
        if [ -d ~/gaianet ]; then  
            # Завершение screen-сессии, если она существует
            if screen -list | grep -q "gaia_request"; then
                screen -S gaia_request -X quit
                show "Сессия 'gaia_request' успешно завершена."
            else
                show_war "Сессия 'gaia_request' не найдена."
            fi
            
            # Удаление директории
            rm -rf ~/gaianet
            show "Директория ~/gaianet и все данные успешно удалены."
        else
            show_war "Директория ~/gaianet не найдена."
        fi
    else
        show_war "Отмена. Данные не удалены."
    fi
}


if [ ! -f ~/gaianet/config.json ]; then
    show_war "Файл config.json не найден. Убедись, что нода установлена."
    exit 1
fi

NODEID=$(jq -r '.address' ~/gaianet/config.json)

menu() {
    case $1 in
        1)  install_dependencies; install_node ;;
        2)  install_requests ;;
        3)  
            echo -en "${TERRACOTTA}${BOLD}Перейди по ссылке и активируй ноду: ${NC}${LIGHT_BLUE} http://$NODEID.us.gaianet.network${NC}\n"
            gaianet info ;;
        9)  
            delete ;;
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






