#!/bin/bash

# Список сетей
NETWORKS=(
    "abstracttestnet"
    "alephzeroevmmainnet"
    "alephzeroevmtestnet"
    "alfajores"
    "ancient8"
    "apechain"
    "appchain"
    "arbitrum"
    "arbitrumnova"
    "arbitrumsepolia"
    "arcadiatestnet2"
    "argochaintestnet"
)

# Функция для вывода списка сетей
print_networks() {
    echo "DEBUG: Вызов print_networks" >&2
    echo "Список доступных сетей:"
    local index=1
    for network in "${NETWORKS[@]}"; do
        printf "%2d. %s\n" "$index" "$network"
        ((index++))
    done
    echo
    # Принудительная отправка данных в терминал
    sleep 0.1
}

# Функция для выбора сети
select_from_list() {
    echo "DEBUG: Вызов select_from_list" >&2
    while true; do
        print_networks
        read -p "Введите номер сети: " user_input
        echo "DEBUG: user_input='$user_input'" >&2

        # Проверка ввода
        if [[ "$user_input" =~ ^[0-9]+$ ]] && (( user_input >= 1 && user_input <= ${#NETWORKS[@]} )); then
            echo "${NETWORKS[user_input - 1]}"
            return 0
        else
            echo "⚠️ Неверный ввод. Попробуйте ещё раз."
        fi
    done
}

# Основная логика
echo "Перед выбором сети:"
echo "DEBUG: Перед вызовом select_from_list" >&2
selected_network=$(select_from_list)
echo "DEBUG: Выбрана сеть: $selected_network" >&2
echo "Вы выбрали сеть: $selected_network"
