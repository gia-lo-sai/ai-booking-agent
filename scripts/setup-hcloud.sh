#!/bin/bash

# Script di configurazione hcloud CLI per ai-booking-agent
# Uso: bash scripts/setup-hcloud.sh

set -e

echo "☁️ Configurazione hcloud CLI per ai-booking-agent"
echo "=================================================="

# Colori
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[→]${NC} $1"
}

# 1. Verifica installazione hcloud
log_step "Verifica installazione hcloud CLI..."

if ! command -v hcloud &> /dev/null; then
    log_warn "hcloud CLI non trovato. Installazione in corso..."
    
    # Determina l'ambiente
    if [[ "$OSTYPE" == "linux-android"* ]]; then
        # Termux
        pkg install -y wget
        npm install -g @hetznercloud/cli
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        wget -q https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz
        tar -xzf hcloud-linux-amd64.tar.gz
        sudo mv hcloud /usr/local/bin/
        rm hcloud-linux-amd64.tar.gz
    else
        log_error "Sistema operativo non supportato. Installa hcloud manualmente."
        exit 1
    fi
    
    log_info "hcloud CLI installato!"
else
    log_info "hcloud CLI già installato: $(hcloud version)"
fi

# 2. Verifica .env
log_step "Verifica configurazione .env..."

if [ ! -f .env ]; then
    log_warn "File .env non trovato. Creo da template..."
    cp .env.example .env
    log_info "File .env creato. Configuralo prima di continuare!"
    echo ""
    log_warn "IMPORTANTE: Modifica .env e aggiungi:"
    echo "  - HCLOUD_TOKEN (da https://console.hetzner.cloud)"
    echo "  - ANTHROPIC_API_KEY (da https://console.anthropic.com)"
    echo ""
    echo "Dopo aver configurato .env, ri-esegui questo script."
    exit 0
fi

# Carica .env
source .env

# 3. Verifica HCLOUD_TOKEN
log_step "Verifica HCLOUD_TOKEN..."

if [ -z "$HCLOUD_TOKEN" ]; then
    log_error "HCLOUD_TOKEN non configurato in .env"
    echo ""
    echo "Ottieni il token da: https://console.hetzner.cloud"
    echo "1. Crea o seleziona un progetto"
    echo "2. Vai su Security → API Tokens"
    echo "3. Genera nuovo token (Read & Write)"
    echo "4. Aggiungi in .env: HCLOUD_TOKEN=your_token_here"
    exit 1
fi

# 4. Configura context hcloud
log_step "Configurazione context hcloud..."

CONTEXT_NAME="${HCLOUD_CONTEXT:-ai-booking-agent}"

# Crea context se non esiste
if hcloud context list | grep -q "$CONTEXT_NAME"; then
    log_info "Context '$CONTEXT_NAME' già esistente"
else
    log_warn "Creazione nuovo context '$CONTEXT_NAME'..."
    hcloud context create "$CONTEXT_NAME"
fi

# Attiva context
hcloud context use "$CONTEXT_NAME"
log_info "Context '$CONTEXT_NAME' attivato"

# Configura token
echo "$HCLOUD_TOKEN" | hcloud context active-token

# 5. Verifica connessione
log_step "Test connessione hcloud..."

if hcloud server list &> /dev/null; then
    log_info "Connessione a hcloud OK!"
    
    echo ""
    echo "📊 Progetti disponibili:"
    hcloud context list
    
    echo ""
    echo "🖥️  Server esistenti:"
    hcloud server list || echo "Nessun server"
    
else
    log_error "Errore connessione hcloud. Verifica il token."
    exit 1
fi

# 6. Verifica/carica chiave SSH
log_step "Gestione chiavi SSH..."

SSH_KEY_NAME="${SSH_KEY_NAME:-ai-booking-key}"

# Verifica se la chiave esiste già su hcloud
if hcloud ssh-key list | grep -q "$SSH_KEY_NAME"; then
    log_info "Chiave SSH '$SSH_KEY_NAME' già presente su hcloud"
else
    log_warn "Caricamento chiave SSH su hcloud..."
    
    # Verifica chiave locale
    if [ -f ~/.ssh/id_rsa.pub ]; then
        hcloud ssh-key create \
            --name "$SSH_KEY_NAME" \
            --public-key-from-file ~/.ssh/id_rsa.pub
        log_info "Chiave SSH '$SSH_KEY_NAME' caricata!"
    elif [ -f ~/.ssh/fish1.pub ]; then
        hcloud ssh-key create \
            --name "$SSH_KEY_NAME" \
            --public-key-from-file ~/.ssh/fish1.pub
        log_info "Chiave SSH '$SSH_KEY_NAME' caricata!"
    else
        log_warn "Nessuna chiave SSH trovata. Generazione nuova chiave..."
        ssh-keygen -t rsa -b 4096 -C "ai-booking-agent" -f ~/.ssh/id_rsa -N ""
        
        hcloud ssh-key create \
            --name "$SSH_KEY_NAME" \
            --public-key-from-file ~/.ssh/id_rsa.pub
        log_info "Nuova chiave SSH generata e caricata!"
    fi
fi

# Aggiorna .env con il nome della chiave
if ! grep -q "SSH_KEY_NAME=" .env; then
    echo "" >> .env
    echo "SSH_KEY_NAME=$SSH_KEY_NAME" >> .env
    log_info "SSH_KEY_NAME aggiunto a .env"
fi

# 7. Verifica ANTHROPIC_API_KEY
log_step "Verifica ANTHROPIC_API_KEY..."

if [ -z "$ANTHROPIC_API_KEY" ]; then
    log_warn "ANTHROPIC_API_KEY non configurato in .env"
    echo ""
    echo "Ottieni l'API key da: https://console.anthropic.com"
    echo "1. Crea account o fai login"
    echo "2. Vai su API Keys"
    echo "3. Crea nuova key"
    echo "4. Aggiungi in .env: ANTHROPIC_API_KEY=sk-ant-..."
else
    log_info "ANTHROPIC_API_KEY configurato"
fi

# 8. Riepilogo configurazione
echo ""
echo "=================================================="
log_info "Configurazione hcloud completata!"
echo "=================================================="
echo ""
echo "📋 Riepilogo:"
echo "  • Context: $CONTEXT_NAME"
echo "  • SSH Key: $SSH_KEY_NAME"
echo "  • Server name: ${SERVER_NAME:-ai-booking-agent}"
echo "  • Server type: ${SERVER_TYPE:-cx11}"
echo "  • Datacenter: ${DATACENTER:-nbg1-dc3}"
echo ""
echo "🚀 Prossimi passi:"
echo ""
echo "  1. Verifica configurazione:"
echo "     cat .env"
echo ""
echo "  2. Testa hcloud:"
echo "     hcloud server list"
echo "     hcloud ssh-key list"
echo ""
echo "  3. Deploy progetto:"
echo "     npm run deploy"
echo "     # oppure"
echo "     bash scripts/deploy.sh"
echo ""
echo "  4. Helper comandi:"
echo "     bash scripts/helper.sh help"
echo ""

# 9. Salva configurazione
CONFIG_FILE="$HOME/.hcloud-ai-booking.conf"
cat > "$CONFIG_FILE" << EOF
# Configurazione hcloud per ai-booking-agent
# Generato: $(date)

CONTEXT=$CONTEXT_NAME
SSH_KEY=$SSH_KEY_NAME
PROJECT=ai-booking-agent
CONFIGURED=$(date +%s)
EOF

log_info "Configurazione salvata in: $CONFIG_FILE"

echo ""
echo "✅ Setup completato! Sei pronto per il deploy."
