#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}-------------------------------------"
echo "|           Chave Assinada          |"
echo "-------------------------------------"
echo "     \\"
echo "      \\"
echo "          .--."
echo "         |o_o |"
echo "         |:_/ |"
echo "        //   \\ \\"
echo "       (|     | )"
echo "      / \\_   _/ \\"
echo "      \\___)=(___/"
echo -e "${NC}"

# Retornar a mensagem desejada
echo -e "${RED}A chave já foi assinada por uma máquina diferente.${NC}"
echo -e "${YELLOW}Este chave pode ser usado apenas em uma única máquina. Por favor, obtenha uma nova chave e tente novamente.${NC}"
