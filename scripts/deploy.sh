#!/bin/bash

# Script di deploy su hcloud per AI Booking Agent
# Uso: bash scripts/deploy.sh

set -e

echo "🚀 Inizio deployment su hcloud..."

# Fix per Termux e fallback per Linux
export TMPDIR="${TMPDIR:-$PREFIX/tmp}"
mkdir -p "$TMPDIR"
TAR_FILE="$TMPDIR/ai-booking-agent.tar.gz"

# Colori per output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Funzione per logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 1. Verifica hcloud CLI
log_info "Verifica hcloud CLI..."
if ! command -v hcloud &> /dev/null; then
    log_error "hcloud CLI non trovato. Installalo con: npm install -g hcloud"
    exit 1
fi

# 2. Verifica .env
if [ ! -f .env ]; then
    log_error "File .env non trovato! Copia .env.example e configura le variabili."
    exit 1
fi

# Carica variabili d'ambiente
source .env

# 3. Verifica API key
if [ -z "$HCLOUD_TOKEN" ]; then
    log_error "HCLOUD_TOKEN non configurato nel file .env"
    exit 1
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    log_error "ANTHROPIC_API_KEY non configurato nel file .env"
    exit 1
fi

# 4. Crea server su hcloud (se non esiste)
SERVER_NAME="${SERVER_NAME:-ai-booking-agent}"
log_info "Verifica server '$SERVER_NAME'..."

SERVER_EXISTS=$(hcloud server list -o noheader | grep -w "$SERVER_NAME" || true)

if [ -z "$SERVER_EXISTS" ]; then
    log_info "Creazione nuovo server su hcloud..."

    hcloud server create \
        --name "$SERVER_NAME" \
        --type "${SERVER_TYPE:-cx23}" \
        --image ubuntu-24.04 \
        --ssh-key "${SSH_KEY_NAME:-luca@phone}" \
        --datacenter "${DATACENTER:-nbg1-dc3}"

    log_info "Server creato! Attendo 30 secondi per l'inizializzazione..."
    sleep 30
else
    log_info "Server '$SERVER_NAME' già esistente."
fi

# 5. Ottieni IP del server
SERVER_IP=$(hcloud server ip "$SERVER_NAME")
log_info "IP del server: $SERVER_IP"

# 6. Copia file sul server
log_info "Copia file sul server..."

# Crea tarball del progetto
tar -czf "$TAR_FILE" \
    --exclude=node_modules \
    --exclude=.git \
    --exclude=frontend/dist \
    --exclude=frontend/node_modules \
    --exclude=backend/node_modules \
    .

# Copia sul server
scp -o StrictHostKeyChecking=no "$TAR_FILE" root@$SERVER_IP:/tmp/

# 7. Setup sul server
log_info "Configurazione server..."

ssh -o StrictHostKeyChecking=no root@$SERVER_IP << 'ENDSSH'
set -e

# Update sistema
apt-get update
apt-get install -y docker.io docker-compose

# Estrai progetto
mkdir -p /opt/ai-booking-agent
cd /opt/ai-booking-agent
tar -xzf /tmp/ai-booking-agent.tar.gz

# Avvia servizi
docker-compose down || true
docker-compose up -d --build

echo "✅ Deployment completato!"
ENDSSH

# 8. Setup database
log_info "Esecuzione migrazioni database..."
ssh -o StrictHostKeyChecking=no root@$SERVER_IP << 'ENDSSH'
cd /opt/ai-booking-agent
docker-compose exec -T backend node migrations/run.js
ENDSSH

# 9. Verifica servizi
log_info "Verifica servizi..."
ssh -o StrictHostKeyChecking=no root@$SERVER_IP << 'ENDSSH'
docker-compose ps
ENDSSH

# 10. Output finale
log_info "=================================="
log_info "✅ Deployment completato con successo!"
log_info "=================================="
log_info ""
log_info "Accedi all'applicazione:"
log_info "  🌐 Frontend: http://$SERVER_IP"
log_info "  🔧 Backend API: http://$SERVER_IP:3001/api/health"
log_info ""
log_info "Comandi utili:"
log_info "  • Logs backend:  ssh root@$SERVER_IP 'cd /opt/ai-booking-agent && docker-compose logs backend'"
log_info "  • Logs frontend: ssh root@$SERVER_IP 'cd /opt/ai-booking-agent && docker-compose logs frontend'"
log_info "  • Restart:       ssh root@$SERVER_IP 'cd /opt/ai-booking-agent && docker-compose restart'"
log_info ""

