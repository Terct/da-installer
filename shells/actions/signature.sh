#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para exibir os termos e condições
mostrar_termos() {

    clear

    # Arte ASCII de aviso/atenção

    echo -e "${RED}-------------------------------------"
    echo "|              ATENÇÃO              |"
    echo "-------------------------------------"
    echo ""
    echo -e "${RED}Por favor, leia atentamente os termos e condições a seguir:${NC}"
    echo ""
    echo ""
    echo -e "${YELLOW}1. Esta chave de instalação é válida apenas para a máquina atual.${NC}"
    echo -e "${YELLOW}2. A chave expira em 3 dias após a assinatura.${NC}"
    echo -e "${YELLOW}3. Você pode repetir a instalação várias vezes na mesma máquina.${NC}"
    echo -e "${YELLOW}4. Certifique-se de revisar cuidadosamente os parâmetros quando solicitado.${NC}"
    echo -e "${YELLOW}5. Não nos responsabilizamos por erros relacionados à instalação.${NC}"
    echo ""
    echo -e "${YELLOW}Ao prosseguir, você concorda com os termos e condições mencionados acima.${NC}"
    echo ""

    sleep 10

    while true; do
        read -p "Você concorda com os termos e condições? (Digite 'yes' para concordar, 'no' para sair): " concordar

        if [ "$concordar" = "yes" ]; then
            realizar_instalacao
            break # Sai do loop se a resposta for 'yes'
        elif [ "$concordar" = "no" ]; then
            echo "Você optou por não concordar com os termos. Instalação cancelada."
            exit 1
        else
            echo "Resposta não reconhecida. Por favor, digite 'yes' ou 'no'."
        fi
    done

}

# Função para realizar a instalação
realizar_instalacao() {
    echo "Iniciando a assinatura..."

    url="https://installer.dagestao.com/update-key-used?ip=$ip&key=$key"

    bash -c "$(curl -fsSL $url)"

    url2="https://installer.dagestao.com/install?app=$app&key=$key"

    bash -c "$(curl -fsSL $url2)"

}

# Função principal
instalador() {
    mostrar_termos

    # Coloque aqui a lógica para assinatura de chave e verificação de expiração

}

# Executar o instalador
instalador
