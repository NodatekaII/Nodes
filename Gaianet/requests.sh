#!/bin/bash

# Цвета для текста
TERRACOTTA='\033[38;5;208m'
LIGHT_BLUE='\033[38;5;117m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Функции для форматирования текста
function show() {
    echo -e "${TERRACOTTA}$1${NC}"
}

function show_bold() {
    echo -en "${TERRACOTTA}${BOLD}$1${NC}"
}

function show_war() {
    echo -e "${RED}${BOLD}$1${NC}"
}

# Проверка прав суперпользователя
if [ "$EUID" -ne 0 ]; then
    show_war "Пожалуйста, запустите скрипт с правами суперпользователя (sudo)."
    exit 1
fi

# Название сессии screen
SCREEN_SESSION_NAME="gaia_request"

# Проверка наличия Python
if ! command -v python3 &> /dev/null; then
    show "Python3 не найден. Устанавливаем..."
    apt update
    apt install python3 -y
else
    show "Python3 уже установлен."
fi

# Установка зависимостей
show "Проверка и установка необходимых зависимостей..."
apt install python3-venv python3-pip jq screen -y

# Получение NODEID из config.json
if [ ! -f ~/gaianet/config.json ]; then
    show_war "Файл ~/gaianet/config.json не найден. Проверьте установку ноды."
    exit 1
fi

NODEID=$(jq -r '.address' ~/gaianet/config.json)
URL_CHAT="https://$NODEID.us.gaianet.network/v1/chat/completions"

# Создание виртуального окружения
VENV_DIR="venv"
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv $VENV_DIR
fi
source $VENV_DIR/bin/activate

# Установка необходимых библиотек
pip3 install --upgrade pip
pip3 install requests faker

# Создание Python-скрипта
PYTHON_SCRIPT_NAME="gaia_request.py"
show "Создание Python-скрипта..."
cat << EOF > $PYTHON_SCRIPT_NAME
import requests
import time
import random
import logging
from faker import Faker

# Настройка логирования
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(message)s")

# URL и заголовки для запросов
url = "$URL_CHAT"
print(f"Используемый URL: {url}")
headers = {
    'accept': 'application/json',
    'Content-Type': 'application/json'
}

# Инициализация Faker
faker = Faker()

# Функция отправки запроса
def send_request():
    try:
        question = faker.sentence(nb_words=10)
        data = {
            "messages": [
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": question}
            ]
        }
        logging.info(f"Отправка запроса с вопросом: {question}")
        response = requests.post(url, headers=headers, json=data)
        if response.status_code == 200:
            logging.info(f"Ответ: {response.json()}")
        else:
            logging.error(f"Ошибка: статус-код {response.status_code}")
    except Exception as e:
        logging.error(f"Ошибка при запросе: {str(e)}")

# Основной цикл
def main():
    while True:
        for _ in range(random.randint(6, 12)):
            send_request()
            time.sleep(random.randint(60, 300))
        logging.info("Перерыв на 30-60 минут...")
        time.sleep(random.randint(1800, 3600))

if __name__ == "__main__":
    main()
EOF

# Проверка существующей screen-сессии
if screen -list | grep -q "$SCREEN_SESSION_NAME"; then
    show_war "Сессия '$SCREEN_SESSION_NAME' уже запущена."
    show_bold "Подключитесь с помощью команды: screen -r $SCREEN_SESSION_NAME"
    exit 1
fi

# Запуск скрипта в screen
show "Запуск Python-скрипта в screen-сессии..."
screen -dmS "$SCREEN_SESSION_NAME" bash -c "source $VENV_DIR/bin/activate && python3 $PYTHON_SCRIPT_NAME"

# Уведомление пользователя
show_bold "Скрипт $PYTHON_SCRIPT_NAME запущен в screen-сессии '$SCREEN_SESSION_NAME'."
show_bold "Для подключения используйте: screen -r $SCREEN_SESSION_NAME"
