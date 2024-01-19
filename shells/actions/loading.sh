#!/bin/bash

loading() {
    local pid=$!
    local delay=0.1
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spin#?}
        printf "\e[38;5;208m[%c] \e[0m" "$spin"
        local spin=$temp${spin%"$temp"}
        sleep $delay
        printf "\b\b\b\b"
    done

    printf "    \b\b\b\b"
}

clear


echo "⌛"
echo -e "\e[38;5;33mCarregando...\e[0m"

# Simula um processo demorado
sleep 3 & loading

# Limpa a linha do loading
printf "\n"

echo -e "\e[38;5;82mCarregamento concluído! Seu conteúdo está pronto.\e[0m"

url2="https://installer.dagestao.com/install?app=$app&key=$key"

bash -c "$(curl -fsSL $url2)"