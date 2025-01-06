#!/bin/bash

NETWORKS=(
    abstracttestnet alephzeroevmmainnet alephzeroevmtestnet alfajores ancient8 apechain
    appchain arbitrum arbitrumnova arbitrumsepolia arcadiatestnet2 argochaintestnet
)

# Упрощённая версия print_networks
print_networks() {
    local networks=("$@")  # Принимаем массив как аргументы
    echo "Список доступных сетей:"
    for i in "${!networks[@]}"; do
        printf " %-3d %-20s\n" $((i + 1)) "${networks[i]}"
    done
    echo ""
}

# Упрощённая версия select_from_list
select_from_list() {
    local input_list=("$@")
    local target=""

    while true; do
        echo "Выберите сеть [введите номер или часть названия]:"
        print_networks "${input_list[@]}"

        echo -n "Ваш выбор: "
        read -r user_input

        echo "DEBUG: user_input='$user_input'"
        echo "DEBUG: input_list=(${input_list[@]})"

        # Если пользователь ввёл номер
        if [[ "$user_input" =~ ^[0-9]+$ ]]; then
            if (( user_input >= 1 && user_input <= ${#input_list[@]} )); then
                target="${input_list[user_input - 1]}"
                echo "✅ Вы выбрали: $target"
                break
            else
                echo "⚠️ Нет такого варианта. Попробуйте снова."
            fi
        elif [[ -n "$user_input" ]]; then
            # Если пользователь ввёл часть названия
            matches=()
            for item in "${input_list[@]}"; do
                if [[ "$item" == *"$user_input"* ]]; then
                    matches+=("$item")
                fi
            done

            if [[ ${#matches[@]} -eq 1 ]]; then
                target="${matches[0]}"
                echo "✅ Вы выбрали: $target"
                break
            elif [[ ${#matches[@]} -gt 1 ]]; then
                echo "⚠️ Найдено несколько совпадений:"
                for i in "${!matches[@]}"; do
                    echo "$((i + 1)). ${matches[i]}"
                done
                echo -n "Ваш уточнённый выбор (номер): "
                read -r refined_input
                if [[ "$refined_input" =~ ^[0-9]+$ && refined_input -ge 1 && refined_input -le ${#matches[@]} ]]; then
                    target="${matches[refined_input - 1]}"
                    echo "✅ Вы выбрали: $target"
                    break
                else
                    echo "⚠️ Неверный выбор. Попробуйте снова."
                fi
            else
                echo "⚠️ Нет совпадений. Попробуйте снова."
            fi
        else
            echo "⚠️ Некорректный ввод. Попробуйте снова."
        fi
    done

    echo "$target"
}

# Тест функции
echo "DEBUG: Перед вызовом select_from_list"
SELECTED_NETWORK=$(select_from_list "${NETWORKS[@]}")
echo "DEBUG: SELECTED_NETWORK=$SELECTED_NETWORK"
