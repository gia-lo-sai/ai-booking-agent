#!/bin/bash

# Script di verifica stato hcloud e progetto ai-booking-agent
# Uso: bash scripts/check-status.sh

echo "🔍 Verifica stato ai-booking-agent su hcloud"
echo "=============================================="
echo ""

# Verifica hcloud
if ! command -v hcloud &> /dev/null; then
    echo "❌ hcloud CLI non installato"
    echo "   Esegui: bash scripts/setup-hcloud.sh"
    exit 1
fi

echo "✅ hcloud CLI: $(hcloud version)"
echo ""

# Context attivo
ACTIVE_CONTEXT=$(hcloud context active 2>/dev/null || echo "none")
echo "📌 Context attivo: $ACTIVE_CONTEXT"
echo ""

# Lista server
echo "🖥️  Server hcloud:"
if hcloud server list &> /dev/null; then
    hcloud server list
else
    echo "   Nessun server o errore di autenticazione"
    echo "   Esegui: bash scripts/setup-hcloud.sh"
fi
echo ""

# Verifica server ai-booking-agent
SERVER_NAME="ai-booking-agent"
if hcloud server describe "$SERVER_NAME" &> /dev/null; then
    echo "✅ Server '$SERVER_NAME' trovato!"
    echo ""
    
    SERVER_IP=$(hcloud server ip "$SERVER_NAME")
    SERVER_STATUS=$(hcloud server describe "$SERVER_NAME" -o json | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    
    echo "   IP: $SERVER_IP"
    echo "   Status: $SERVER_STATUS"
    echo ""
    
    # Test connessione SSH
    echo "🔐 Test connessione SSH..."
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$SERVER_IP "echo '✅ SSH OK'" 2>/dev/null; then
        echo ""
        
        # Verifica servizi Docker
        echo "🐳 Verifica servizi Docker..."
        ssh -o StrictHostKeyChecking=no root@$SERVER_IP "cd /opt/ai-booking-agent && docker-compose ps" 2>/dev/null || echo "   Servizi non ancora deployati"
        echo ""
        
        # URL accesso
        echo "🌐 Accesso applicazione:"
        echo "   Frontend: http://$SERVER_IP"
        echo "   API: http://$SERVER_IP:3001/api/health"
    else
        echo "   ❌ SSH non raggiungibile"
    fi
else
    echo "⚠️  Server '$SERVER_NAME' non trovato"
    echo "   Esegui deploy con: npm run deploy"
fi
echo ""

# Verifica chiavi SSH
echo "🔑 Chiavi SSH su hcloud:"
hcloud ssh-key list
echo ""

# Verifica .env locale
if [ -f .env ]; then
    echo "✅ File .env presente"
    
    source .env
    
    # Check variabili critiche
    [ -n "$HCLOUD_TOKEN" ] && echo "   ✅ HCLOUD_TOKEN configurato" || echo "   ❌ HCLOUD_TOKEN mancante"
    [ -n "$ANTHROPIC_API_KEY" ] && echo "   ✅ ANTHROPIC_API_KEY configurato" || echo "   ❌ ANTHROPIC_API_KEY mancante"
    [ -n "$POSTGRES_PASSWORD" ] && echo "   ✅ POSTGRES_PASSWORD configurato" || echo "   ⚠️  POSTGRES_PASSWORD usa default"
else
    echo "❌ File .env non trovato"
    echo "   Esegui: bash scripts/setup-hcloud.sh"
fi
echo ""

echo "=============================================="
echo "Comandi utili:"
echo "  • Setup: bash scripts/setup-hcloud.sh"
echo "  • Deploy: npm run deploy"
echo "  • Logs: bash scripts/helper.sh logs"
echo "  • SSH: bash scripts/helper.sh ssh"
