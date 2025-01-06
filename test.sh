#!/bin/bash

# Список сетей
NETWORKS=(
    abstracttestnet alephzeroevmmainnet alephzeroevmtestnet alfajores ancient8 apechain
    appchain arbitrum arbitrumnova arbitrumsepolia arcadiatestnet2 argochaintestnet
)

# Функция для вывода списка сетей
print_networks() {
    echo "Список доступных сетей:"
    for i in "${!NETWORKS[@]}"; do
        printf "%3d. %s\n" $((i + 1)) "${NETWORKS[i]}"
    done
}

# Функция для выбора сети
select_from_list() {
    while true; do
        # Выводим список сетей
        print_networks
        read -p "Введите номер сети: " user_input
        # Проверяем корректность ввода
        if [[ "$user_input" =~ ^[0-9]+$ ]] && (( user_input >= 1 && user_input <= ${#NETWORKS[@]} )); then
            echo "${NETWORKS[user_input - 1]}"
            return
        else
            echo "⚠️ Неверный ввод. Попробуйте ещё раз."
        fi
    done
}

# Основная логика
echo "Перед выбором сети:"
selected_network=$(select_from_list)
echo "Вы выбрали сеть: $selected_network"
