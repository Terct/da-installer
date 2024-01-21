#!/bin/bash
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para confirmar a desinstalação
function confirmar_desinstalacao() {
  echo -e "${RED}ATENÇÃO: Esta ação irá desinstalar a aplicação Evolution-API e todos os dados associados. Tem certeza de que deseja continuar?${NC}"
  read -p "Digite 'sim' para confirmar: " confirmacao
  if [ "$confirmacao" != "sim" ]; then
    echo "Desinstalação cancelada."
    exit 0
  fid
}

# ... (seu código anterior)

# Confirmação antes de prosseguir com a desinstalação
confirmar_desinstalacao

# Remove o stack do Docker
docker stack rm evolution_stack mongodb_stack

# Remove os volumes
docker volume rm evolution_dagestao_instances
docker volume rm evolution_dagestao_store

docker volume rm mongodb_configdb_data
docker volume rm mongodb_data


# Remove o diretório de instalação
rm -rf /opt/evolution/
rm -rf /opt/mongodb/

# ... (seu código anterior)
echo ""
echo -e "${BLUE}-------------------------------------"
echo "|    Desinstalação Concluída        |"
echo "-------------------------------------"
echo -e "${NC}"
echo ""