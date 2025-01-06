#!/bin/bash

NETWORKS=(
    abstracttestnet alephzeroevmmainnet alephzeroevmtestnet alfajores ancient8 apechain
    appchain arbitrum arbitrumnova arbitrumsepolia arcadiatestnet2 argochaintestnet
)

# Функция для отображения списка сетей
print_networks() {
    local -n networks_ref=$1
    echo "Список доступных сетей:"
    for i in "${!networks_ref[@]}"; do
        printf "%3d. %s\n" $((i + 1)) "${networks_ref[i]}"
    done
    echo "DEBUG: Завершён вывод списка сетей."
}

# Функция для выбора из списка
select_from_list() {
    local -n input_list=$1
    echo "DEBUG: Вызов select_from_list. Длина списка: ${#input_list[@]}"
    while true; do
        print_networks input_list
        read -p "Введите номер сети: " user_input
        echo "DEBUG: Введено значение: $user_input"
        if [[ "$user_input" =~ ^[0-9]+$ ]] && (( user_input >= 1 && user_input <= ${#input_list[@]} )); then
            echo "${input_list[user_input - 1]}"
            return
        else
            echo "⚠️ Неверный ввод. Попробуйте ещё раз."
        fi
    done
}

# Основная проверка
echo "DEBUG: Перед вызовом select_from_list"
selected_network=$(select_from_list NETWORKS)
echo "DEBUG: Выбранная сеть: $selected_network"
