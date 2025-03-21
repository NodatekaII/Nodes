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
    echo "DEBUG: Вызов print_networks"
    echo "Список доступных сетей:"
    local index=1
    for network in "${NETWORKS[@]}"; do
        echo "$index) $network"
        ((index++))
    done
    echo
}

# Функция для выбора сети
select_from_list() {
    echo "DEBUG: Вызов select_from_list"
    print_networks

    while true; do
        echo -n "Введите номер сети: "
        read -r user_input
        echo "DEBUG: user_input='$user_input'"

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
echo "DEBUG: Перед выбором сети"
selected_network=$(select_from_list)
echo "Вы выбрали сеть: $selected_network"
