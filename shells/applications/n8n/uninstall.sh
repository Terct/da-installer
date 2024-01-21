#!/bin/bash
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color


echo ""
echo -e "${BLUE}-------------------------------------"
echo "|           DESINSTALAÇÃO           |"
echo "-------------------------------------"
echo -e "${NC}"
echo ""


# Função para confirmar a desinstalação
function confirmar_desinstalacao() {
  echo -e "${RED}ATENÇÃO: Esta ação irá desinstalar a aplicação n8n e todos os dados associados. Tem certeza de que deseja continuar?${NC}"
  read -p "Digite 'sim' para confirmar: " confirmacao
  if [ "$confirmacao" != "sim" ]; then
    echo "Desinstalação cancelada."
    exit 0
  fi
}

# ... (seu código anterior)

# Confirmação antes de prosseguir com a desinstalação
confirmar_desinstalacao

# Remove o stack do Docker
docker stack rm n8n_stack

echo ""
echo -e "${YELLOW}Deletando Volumes...${NC}"
sleep 10



# Remove os volumes
docker volume rm redis_data
docker volume rm postgres_data

# Remove o diretório de instalação
rm -rf /opt/n8n/

# ... (seu código anterior)

echo ""
echo -e "${BLUE}-------------------------------------"
echo "|    Desinstalação Concluída        |"
echo "-------------------------------------"
echo -e "${NC}"
echo ""