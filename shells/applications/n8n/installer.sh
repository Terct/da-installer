#!/bin/bash
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

clear

echo -e "${BLUE}-------------------------------------"
echo "|             SETUP N8N              |"
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

# Solicita o subdomínio para webhooks e valida
while true; do
  echo -e "${GREEN}Digite o subdomínio para o seu n8n (por exemplo, n8n.seudominio.com): ${NC}"
  read -p "subdomínio: " subdominio_n8n
  if [ -n "$subdominio_n8n" ] && validar_dominio "$subdominio_n8n"; then
    break
  fi
done

# Verifica se os subdomínios resolvem para os IPs locais da máquina
seu_ip=$(hostname -I | cut -d' ' -f1) # Obtém o primeiro IP associado à máquina

# Verifica para n8n
if [ "$(nslookup "$subdominio_n8n" | awk '/^Address:/ && !/#/ {print $2}')" != "$seu_ip" ]; then
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



# Cria o diretório se não existir
mkdir -p /opt/n8n/

# Cria o arquivo docker-compose.yml no diretório /opt/traefik
cat <<EOF >/opt/n8n/docker-compose.yml

version: "3.7"

services:

  n8n-db:
    image: postgres:14
    environment:
      - POSTGRES_DB=n8n_queue
      - POSTGRES_PASSWORD=n8nPassWord
    networks:
      - dagestao_network
    #ports:
    #  - 5432:5432
    volumes:
      - postgres_data:/var/lib/postgresql/data
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager


  redis:
    image: redis:latest
    command: [
        "redis-server",
        "--appendonly",
        "yes",
        "--port",
        "6379"
      ]
    volumes:
      - redis_data:/data
    networks:
      - dagestao_network
    deploy:
      placement:
        constraints:
          - node.role == manager



  n8n_editor:
    image: n8nio/n8n:latest
    command: start
    networks:
      - dagestao_network
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_DATABASE=n8n_queue
      - DB_POSTGRESDB_HOST=n8n-db
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_PASSWORD=n8nPassWord
      - N8N_ENCRYPTION_KEY=r3djGX2vPoeL9zKL
      - N8N_HOST=${subdominio_n8n}
      - N8N_EDITOR_BASE_URL=https://${subdominio_n8n}/
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${subdominio_n8n}/
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
      - QUEUE_BULL_REDIS_DB=2
      - NODE_FUNCTION_ALLOW_EXTERNAL=moment,lodash,moment-with-locales
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=336
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - TZ=America/Sao_Paulo
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      labels:
        - traefik.enable=true
        - traefik.http.routers.n8n_editor.rule=Host(\`${subdominio_n8n}\`)
        - traefik.http.routers.n8n_editor.entrypoints=websecure
        - traefik.http.routers.n8n_editor.priority=1
        - traefik.http.routers.n8n_editor.tls.certresolver=letsencryptresolver
        - traefik.http.routers.n8n_editor.service=n8n_editor
        - traefik.http.services.n8n_editor.loadbalancer.server.port=5678
        - traefik.http.services.n8n_editor.loadbalancer.passHostHeader=1

  n8n_webhook:
    image: n8nio/n8n:latest
    command: webhook
    networks:
      - dagestao_network
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_DATABASE=n8n_queue
      - DB_POSTGRESDB_HOST=n8n-db
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_PASSWORD=n8nPassWord
      - N8N_ENCRYPTION_KEY=r3djGX2vPoeL9zKL
      - N8N_HOST=${subdominio_n8n}
      - N8N_EDITOR_BASE_URL=https://${subdominio_n8n}/
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${subdominio_n8n}/
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
      - QUEUE_BULL_REDIS_DB=2
      - NODE_FUNCTION_ALLOW_EXTERNAL=moment,lodash,moment-with-locales
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=336
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - TZ=America/Sao_Paulo
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager
      labels:
        - traefik.enable=true
        - traefik.http.routers.n8n_webhook.rule=Host(\`${subdominio_n8n}\`)
        - traefik.http.routers.n8n_webhook.entrypoints=websecure
        - traefik.http.routers.n8n_webhook.priority=1
        - traefik.http.routers.n8n_webhook.tls.certresolver=letsencryptresolver
        - traefik.http.routers.n8n_webhook.service=n8n_webhook
        - traefik.http.services.n8n_webhook.loadbalancer.server.port=5678
        - traefik.http.services.n8n_webhook.loadbalancer.passHostHeader=1

  n8n_worker:
    image: n8nio/n8n:latest
    command: worker --concurrency=10
    networks:
      - dagestao_network
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_DATABASE=n8n_queue
      - DB_POSTGRESDB_HOST=n8n-db
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_USER=postgres
      - DB_POSTGRESDB_PASSWORD=n8nPassWord
      - N8N_ENCRYPTION_KEY=r3djGX2vPoeL9zKL
      - N8N_HOST=${subdominio_n8n}
      - N8N_EDITOR_BASE_URL=https://${subdominio_n8n}/
      - N8N_PROTOCOL=https
      - NODE_ENV=production
      - WEBHOOK_URL=https://${subdominio_n8n}/
      - EXECUTIONS_MODE=queue
      - QUEUE_BULL_REDIS_HOST=redis
      - QUEUE_BULL_REDIS_PORT=6379
      - QUEUE_BULL_REDIS_DB=2
      - NODE_FUNCTION_ALLOW_EXTERNAL=moment,lodash,moment-with-locales
      - EXECUTIONS_DATA_PRUNE=true
      - EXECUTIONS_DATA_MAX_AGE=336
      - GENERIC_TIMEZONE=America/Sao_Paulo
      - TZ=America/Sao_Paulo
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints:
          - node.role == manager

volumes:
  redis_data:
    external: true
    name: redis_data
  postgres_data:
    external: true
    name: postgres_data


networks:
  dagestao_network:
    name: dagestao_network
    external: true

EOF

# Implanta o stack com Docker deploy
docker-compose -f /opt/n8n/docker-compose.yml pull

docker stack deploy -c /opt/n8n/docker-compose.yml n8n_stack


echo ""

echo -e "${BLUE}-------------------------------------"
echo "|       Instalação Concluida        |"
echo "-------------------------------------"
echo -e "${NC}"


# Cria um arquivo de texto com as credenciais
echo -e "Credenciais do N8N Stack\n" > /opt/n8n/credenciais.txt
echo -e "-------------------------------------" >> /opt/n8n/credenciais.txt
echo -e "Subdomínio N8N: $subdominio_n8n" >> /opt/n8n/credenciais.txt
echo -e "Postgres Database: n8n_queue" >> /opt/n8n/credenciais.txt
echo -e "Postgres User: postgres" >> /opt/n8n/credenciais.txt
echo -e "Postgres Password: n8nPassWord" >> /opt/n8n/credenciais.txt
echo -e "Redis Database: 2" >> /opt/n8n/credenciais.txt
echo -e "Redis Port: 6379" >> /opt/n8n/credenciais.txt
echo -e "Encryption Key: r3djGX2vPoeL9zKL" >> /opt/n8n/credenciais.txt
echo -e "-------------------------------------" >> /opt/n8n/credenciais.txt

echo -e "${RED}Credenciais adicionadas ao arquivo /opt/n8n/credenciais.txt${NC}"

echo ""
echo ""

echo -e "${YELLOW}Suas Credenciais:${NC}"
echo ""

cat /opt/n8n/credenciais.txt
echo ""