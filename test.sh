# Тестовый скрипт
NETWORKS=("ethereum" "polygon" "bsc" "avalanche")

print_networks() {
    local -n networks_ref=$1
    for i in "${!networks_ref[@]}"; do
        echo "$((i + 1)). ${networks_ref[i]}"
    done
}

select_from_list() {
    local -n input_list_ref=$1
    local prompt="$2"
    while true; do
        print_networks input_list_ref
        read -p "$prompt: " choice
        echo "Вы выбрали: $choice"
        break
    done
}

select_from_list NETWORKS "Выберите сеть"
