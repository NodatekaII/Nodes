#!/bin/bash

NETWORKS=(abstracttestnet alephzeroevmmainnet alephzeroevmtestnet alfajores)

print_networks() {
    echo "Список доступных сетей:"
    for i in "${!NETWORKS[@]}"; do
        echo "$((i + 1)). ${NETWORKS[i]}"
    done
    echo ""
}

select_from_list() {
    echo "DEBUG: input_list=(${NETWORKS[@]})"
    print_networks
    read -p "Введите номер сети: " user_input
    echo "DEBUG: user_input='$user_input'"
}

# Тест функции
echo "DEBUG: Перед вызовом select_from_list"
select_from_list
echo "DEBUG: После вызова select_from_list"
