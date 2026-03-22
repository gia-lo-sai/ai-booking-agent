# ⚡ Quick Start - AI Booking Agent

Guida rapida per iniziare in 5 minuti!

## 📱 Su Termux (Deployment Produzione)

```bash
# 1. Setup iniziale
bash scripts/setup-termux.sh

# 2. Configura credenziali
cp .env.example .env
nano .env  # Aggiungi ANTHROPIC_API_KEY e HCLOUD_TOKEN

# 3. Deploy su hcloud
npm run deploy

# 4. Accedi all'app
# http://YOUR_SERVER_IP
```

## 💻 Sviluppo Locale

```bash
# 1. Installa dipendenze
npm install
cd backend && npm install && cd ..
cd frontend && npm install && cd ..

# 2. Configura environment
cp .env.example .env
# Modifica DATABASE_URL per localhost

# 3. Avvia PostgreSQL
docker-compose up postgres -d

# 4. Esegui migrazioni
cd backend && npm run migrate && cd ..

# 5. Avvia dev server
npm run dev

# 6. Apri browser
# http://localhost:5173
```

## 🔑 Ottieni API Keys

### Anthropic Claude
1. https://console.anthropic.com
2. Crea account → API Keys → New Key
3. Copia in `.env` → `ANTHROPIC_API_KEY=sk-ant-...`

### Hetzner Cloud
1. https://console.hetzner.cloud
2. Nuovo progetto → Security → API Tokens
3. Genera token (Read & Write)
4. Copia in `.env` → `HCLOUD_TOKEN=...`

## 🚀 Comandi Rapidi

```bash
# Helper script
bash scripts/helper.sh help

# Deploy
bash scripts/helper.sh deploy

# Logs server
bash scripts/helper.sh logs

# SSH server
bash scripts/helper.sh ssh

# Backup database
bash scripts/helper.sh backup
```

## 🐛 Problemi?

### "hcloud command not found"
```bash
npm install -g @hetznercloud/cli
```

### "Database connection error"
```bash
# Verifica PostgreSQL
docker-compose ps
docker-compose logs postgres

# Restart
docker-compose restart postgres
```

### "Claude API error"
```bash
# Verifica API key in .env
cat .env | grep ANTHROPIC_API_KEY

# Test connessione
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: YOUR_KEY" \
  -H "anthropic-version: 2023-06-01"
```

## 📚 Documentazione Completa

Vedi [README.md](README.md) per la guida completa.

## 🎯 Prossimi Passi

Dopo il deploy:

1. ✅ Testa la chat AI
2. ✅ Prova a creare un appuntamento
3. ✅ Personalizza il brand (`BUSINESS_NAME` in `.env`)
4. ✅ Configura HTTPS (Let's Encrypt)
5. ✅ Setup backup automatici
6. ✅ Aggiungi email notifications

Buon coding! 🚀
