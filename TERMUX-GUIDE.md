# 📱 Guida Termux - ai-booking-agent con hcloud

Guida completa per usare **ai-booking-agent** su Termux con hcloud CLI.

## 🚀 Setup Iniziale (Solo Prima Volta)

### 1. Estrai il progetto
```bash
cd ~/
tar -xzf ai-booking-agent.tar.gz
cd ai-booking-agent
```

### 2. Inizializza progetto
```bash
# Script automatico completo
bash scripts/init.sh
```

Oppure manualmente:

```bash
# Setup hcloud
bash scripts/setup-hcloud.sh

# Crea .env
cp .env.example .env
nano .env  # Modifica con le tue credenziali
```

### 3. Configura credenziali in .env

```bash
nano .env
```

Aggiungi:
```env
HCLOUD_TOKEN=your_hetzner_token_here
ANTHROPIC_API_KEY=sk-ant-your_key_here
POSTGRES_PASSWORD=ScegliPasswordSicura123!
```

**Dove ottenere le credenziali:**

#### Hetzner Cloud Token
1. Vai su https://console.hetzner.cloud
2. Crea/seleziona progetto
3. Security → API Tokens
4. Generate (Read & Write)

#### Anthropic API Key
1. Vai su https://console.anthropic.com
2. API Keys → Create Key
3. Copia (inizia con `sk-ant-`)

## 📋 Comandi npm (Raccomandati)

```bash
# Verifica stato hcloud
npm run hcloud:status

# Deploy completo
npm run deploy

# Visualizza logs
npm run hcloud:logs

# Connetti via SSH
npm run hcloud:ssh

# Restart servizi
npm run hcloud:restart

# Backup database
npm run hcloud:backup
```

## 🔧 Comandi hcloud Diretti

### Gestione Server

```bash
# Lista server
hcloud server list

# Crea server ai-booking-agent
hcloud server create \
  --name ai-booking-agent \
  --type cx11 \
  --image ubuntu-22.04 \
  --ssh-key ai-booking-key

# Ottieni IP
hcloud server ip ai-booking-agent

# Descrizione server
hcloud server describe ai-booking-agent

# Elimina server
hcloud server delete ai-booking-agent
```

### Gestione SSH Keys

```bash
# Lista chiavi
hcloud ssh-key list

# Carica chiave
hcloud ssh-key create \
  --name ai-booking-key \
  --public-key-from-file ~/.ssh/id_rsa.pub

# Elimina chiave
hcloud ssh-key delete ai-booking-key
```

### Context Management

```bash
# Lista context
hcloud context list

# Crea context
hcloud context create ai-booking-agent

# Attiva context
hcloud context use ai-booking-agent

# Context attivo
hcloud context active
```

### Network & Firewall

```bash
# Crea network
hcloud network create \
  --name ai-booking-network \
  --ip-range 10.0.0.0/16

# Lista firewall
hcloud firewall list

# Crea firewall
hcloud firewall create \
  --name ai-booking-firewall
```

## 🚀 Workflow Tipico

### Deploy Iniziale
```bash
# 1. Verifica configurazione
npm run hcloud:status

# 2. Deploy
npm run deploy

# 3. Attendi completamento (5-10 min)

# 4. Ottieni IP
hcloud server ip ai-booking-agent

# 5. Accedi all'app
# http://YOUR_SERVER_IP
```

### Aggiornamenti
```bash
# 1. Modifica codice

# 2. Re-deploy
npm run deploy

# 3. Verifica servizi
npm run hcloud:logs
```

### Monitoraggio
```bash
# Status generale
npm run hcloud:status

# Logs in tempo reale
npm run hcloud:ssh
cd /opt/ai-booking-agent
docker-compose logs -f

# Solo backend
docker-compose logs -f backend

# Solo frontend
docker-compose logs -f frontend

# Solo database
docker-compose logs -f postgres
```

### Manutenzione
```bash
# Backup database
npm run hcloud:backup

# Restart servizi
npm run hcloud:restart

# Aggiornamento sistema
npm run hcloud:ssh
apt update && apt upgrade -y
docker-compose down && docker-compose up -d --build
```

## 🐛 Troubleshooting Termux

### hcloud command not found
```bash
# Verifica installazione
which hcloud

# Reinstalla
npm install -g @hetznercloud/cli

# Verifica
hcloud version
```

### Permission denied
```bash
# Rendi eseguibili gli script
chmod +x scripts/*.sh

# Se persiste, usa bash esplicito
bash scripts/deploy.sh
```

### SSH connection failed
```bash
# Genera nuova chiave
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Carica su hcloud
hcloud ssh-key create \
  --name ai-booking-key \
  --public-key-from-file ~/.ssh/id_rsa.pub

# Verifica connessione
SERVER_IP=$(hcloud server ip ai-booking-agent)
ssh -o StrictHostKeyChecking=no root@$SERVER_IP
```

### Docker errors
```bash
# Connetti al server
npm run hcloud:ssh

# Verifica Docker
systemctl status docker

# Restart Docker
systemctl restart docker

# Rebuild containers
cd /opt/ai-booking-agent
docker-compose down
docker-compose up -d --build
```

## 💾 Backup & Restore

### Backup Database
```bash
# Automatico
npm run hcloud:backup

# Manuale
SERVER_IP=$(hcloud server ip ai-booking-agent)
ssh root@$SERVER_IP \
  "docker-compose exec -T postgres pg_dump -U bookinguser booking_db" \
  > backup-$(date +%Y%m%d).sql
```

### Restore Database
```bash
# Copia backup su server
scp backup-20260322.sql root@$SERVER_IP:/tmp/

# Connetti e restore
npm run hcloud:ssh
cd /opt/ai-booking-agent
cat /tmp/backup-20260322.sql | \
  docker-compose exec -T postgres psql -U bookinguser booking_db
```

## 📊 Costi Hetzner Cloud

Server **cx11** (raccomandato):
- 1 vCPU
- 2 GB RAM
- 20 GB SSD
- **€4.15/mese** (~€0.006/ora)

Upgrade disponibili:
- **cx21**: 2 vCPU, 4 GB RAM - €7.00/mese
- **cx31**: 2 vCPU, 8 GB RAM - €13.00/mese

## 🎯 Tips & Best Practices

### Performance
```bash
# Monitor risorse
npm run hcloud:ssh
htop

# Logs Docker
docker stats
```

### Sicurezza
```bash
# Cambia password database
nano .env  # Modifica POSTGRES_PASSWORD
npm run deploy  # Re-deploy

# Setup firewall
hcloud firewall create --name ai-booking-fw
hcloud firewall add-rule ai-booking-fw \
  --direction in --protocol tcp --port 22 --source-ips 0.0.0.0/0
hcloud firewall add-rule ai-booking-fw \
  --direction in --protocol tcp --port 80 --source-ips 0.0.0.0/0
```

### Automazione
```bash
# Backup automatico giornaliero (aggiungi a crontab)
0 3 * * * cd ~/ai-booking-agent && npm run hcloud:backup

# Monitor uptime
*/5 * * * * curl -f http://YOUR_IP/api/health || npm run hcloud:restart
```

## 🔗 Link Utili

- Hetzner Console: https://console.hetzner.cloud
- Anthropic Console: https://console.anthropic.com
- hcloud CLI Docs: https://docs.hetzner.cloud
- Docker Docs: https://docs.docker.com

## 📞 Supporto

Issues GitHub: [tuo-repo]/issues
Email: [tua-email]

---

Sviluppato con ❤️ su Termux + hcloud
