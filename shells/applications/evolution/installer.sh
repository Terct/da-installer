#!/bin/bash
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clear

echo -e "${BLUE}-------------------------------------"
echo "|          SETUP EVOLUTION           |"
echo "-------------------------------------"
echo -e "${NC}"
echo ""

# Função para validar o formato de domínio
function validar_dominio() {
  local dominio=$1
  local regex="^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

  if [[ $dominio =~ $regex ]]; then
    echo ""
    return 0
  else
    echo -e "${RED}Domínio inválido. Por favor, tente novamente.${NC}"
    return 1
  fi
}

# Solicita o domínio e valida
while true; do
  echo -e "${GREEN}Digite o subdominio para sua Evolution-API (por exemplo, evolution.seudominio.com): ${NC}"
  read -p "subdomínio: " subdominio
  if [ -n "$subdominio" ] && validar_dominio "$subdominio"; then
    break
  fi
done

# Verifica se o subdomínio resolve para o IP local da máquina
seu_ip=$(hostname -I | cut -d' ' -f1) # Obtém o primeiro IP associado à máquina
if [ "$(nslookup "$subdominio" | awk '/^Address:/ && !/#/ {print $2}')" != "$seu_ip" ]; then
  echo -e "${RED}Erro: O subdomínio não está apontado para o IP local da sua máquina.${NC}"
  echo ""
  exit 1
else
  echo ""
fi




echo -e "${YELLOW}-------------------------------------"
echo "|            Instalando...           |"
echo "-------------------------------------"
echo -e "${NC}"
echo ""



api_key=$(openssl rand -hex 16)


# Cria o diretório se não existir
mkdir -p /opt/mongodb/

# Cria o arquivo docker-compose.yml no diretório /opt/traefik
cat <<EOF >/opt/mongodb/docker-compose.yml

version: "3.7"

services:
  mongodb:
    image: mongo:7
    command: mongod --port 27017
    networks:
      - dagestao_network
    volumes:
      - mongodb_data:/data/db
      - mongodb_configdb_data:/data/configdb
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=Mfcd62!!Mfcd62!!
      - PUID=1000
      - PGID=1000
    ports:
      - 27017:27017
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "1"
          memory: 1024M

volumes:
  mongodb_data:
    external: true
    name: mongodb_data
  mongodb_configdb_data:
    external: true
    name: mongodb_configdb_data

networks:
  dagestao_network:
    external: true
    name: dagestao_network

EOF



# Implanta o stack com Docker deploy
docker-compose -f /opt/mongodb/docker-compose.yml pull
docker stack deploy -c /opt/mongodb/docker-compose.yml mongodb_stack

# Cria o diretório se não existir
mkdir -p /opt/evolution/

# Cria o arquivo docker-compose.yml no diretório /opt/traefik
cat <<EOF >/opt/evolution/docker-compose.yml
version: "3.7"

services:
  evolution_dagestao:
    image: davidsongomes/evolution-api:v1.5.4
    command: ["node", "./dist/src/main.js"]
    networks:
      - dagestao_network
    volumes:
    - evolution_dagestao_instances:/evolution/instances
    - evolution_dagestao_store:/evolution/store
    environment:
      - SERVER_URL=https://${subdominio}
      - DOCKER_ENV=true
      - LOG_LEVEL=ERROR,WARN,DEBUG,INFO,LOG,VERBOSE,DARK,WEBHOOKS
      - DEL_INSTANCE=false
      - CONFIG_SESSION_PHONE_CLIENT=Evolution
      - CONFIG_SESSION_PHONE_NAME=Chrome
      - STORE_MESSAGES=true
      - STORE_MESSAGE_UP=true
      - STORE_CONTACTS=true
      - STORE_CHATS=true
      - CLEAN_STORE_CLEANING_INTERVAL=7200 # seconds === 2h
      - CLEAN_STORE_MESSAGES=true
      - CLEAN_STORE_MESSAGE_UP=true
      - CLEAN_STORE_CONTACTS=true
      - CLEAN_STORE_CHATS=true
      - AUTHENTICATION_TYPE=apikey
      - AUTHENTICATION_API_KEY=${api_key}
      - AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES=true
      - QRCODE_LIMIT=30
      - WEBHOOK_GLOBAL_ENABLED=false
      - WEBHOOK_GLOBAL_URL=https://URL
      - WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS=false
      - WEBHOOK_EVENTS_APPLICATION_STARTUP=false
      - WEBHOOK_EVENTS_QRCODE_UPDATED=true
      - WEBHOOK_EVENTS_MESSAGES_SET=false
      - WEBHOOK_EVENTS_MESSAGES_UPSERT=true
      - WEBHOOK_EVENTS_MESSAGES_UPDATE=true
      - WEBHOOK_EVENTS_CONTACTS_SET=true
      - WEBHOOK_EVENTS_CONTACTS_UPSERT=true
      - WEBHOOK_EVENTS_CONTACTS_UPDATE=true
      - WEBHOOK_EVENTS_PRESENCE_UPDATE=true
      - WEBHOOK_EVENTS_CHATS_SET=true
      - WEBHOOK_EVENTS_CHATS_UPSERT=true
      - WEBHOOK_EVENTS_CHATS_UPDATE=true
      - WEBHOOK_EVENTS_CHATS_DELETE=true
      - WEBHOOK_EVENTS_GROUPS_UPSERT=true
      - WEBHOOK_EVENTS_GROUPS_UPDATE=true
      - WEBHOOK_EVENTS_GROUP_PARTICIPANTS_UPDATE=true
      - WEBHOOK_EVENTS_CONNECTION_UPDATE=true
      - REDIS_ENABLED=false
      - REDIS_URI=redis://redis:6379
      # Aivar Banco de Dados
      - DATABASE_ENABLED=true
      - DATABASE_CONNECTION_URI=mongodb://admin:Mfcd62!!Mfcd62!!@$seu_ip:27017/?authSource=admin&readPreference=primary&ssl=false&directConnection=true
      - DATABASE_CONNECTION_DB_PREFIX_NAME=evo
      # Escolha o que deseja salvar
      - DATABASE_SAVE_DATA_INSTANCE=true
      - DATABASE_SAVE_DATA_NEW_MESSAGE=false
      - DATABASE_SAVE_MESSAGE_UPDATE=false
      - DATABASE_SAVE_DATA_CONTACTS=false
      - DATABASE_SAVE_DATA_CHATS=false
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      resources:
        limits:
          cpus: "1"
          memory: 2048M
      labels:
        - traefik.enable=true
        - traefik.http.routers.evolution_dagestao.rule=Host(\`${subdominio}\`)
        - traefik.http.routers.evolution_dagestao.entrypoints=websecure
        - traefik.http.routers.evolution_dagestao.tls.certresolver=letsencryptresolver
        - traefik.http.routers.evolution_dagestao.priority=1
        - traefik.http.routers.evolution_dagestao.service=evolution_dagestao
        - traefik.http.services.evolution_dagestao.loadbalancer.server.port=8080
        - traefik.http.services.evolution_dagestao.loadbalancer.passHostHeader=true

volumes:
  evolution_dagestao_instances:
    external: true
    name: evolution_dagestao_instances
  evolution_dagestao_store:
    external: true
    name: evolution_dagestao_store

networks:
  dagestao_network:
    name: dagestao_network
    external: true

EOF

# Implanta o stack com Docker deploy
docker-compose -f /opt/evolution/docker-compose.yml pull
docker stack deploy -c /opt/evolution/docker-compose.yml evolution_stack


echo ""

echo -e "${BLUE}-------------------------------------"
echo "|       Instalação Concluida        |"
echo "-------------------------------------"
echo -e "${NC}"


# Cria um arquivo de texto com as credenciais
echo -e "Credenciais do Evolution Stack\n" > /opt/evolution/credenciais.txt
echo -e "-------------------------------------" >> /opt/evolution/credenciais.txt
echo -e "Subdomínio Evolution: $subdominio" >> /opt/evolution/credenciais.txt
echo -e "MongoDB Root User: admin" >> /opt/evolution/credenciais.txt
echo -e "MongoDB Root Password: Mfcd62!!Mfcd62!!" >> /opt/evolution/credenciais.txtdocker ps
echo -e "API Key: $api_key" >> /opt/evolution/credenciais.txt
echo -e "-------------------------------------" >> /opt/evolution/credenciais.txt


echo -e "${RED}Credenciais adicionadas ao arquivo /opt/evolution/credenciais.txt${NC}"

echo ""
echo ""

echo -e "${YELLOW}Suas Credenciais:${NC}"
echo ""

cat /opt/evolution/credenciais.txt
echo ""