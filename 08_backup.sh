#!/bin/bash
# 08_backup.sh - backup lógico diário do PostgreSQL (formato custom -Fc)
set -euo pipefail

# Lê a connection string de fora do repositório (nunca commitar senha)
[ -f "$HOME/.hospital_env" ] && source "$HOME/.hospital_env"
: "${DATABASE_URL:?Defina DATABASE_URL em ~/.hospital_env}"

BACKUP_DIR="${BACKUP_DIR:-$HOME/backups_hospital}"
RETENCAO_DIAS=30
DATA=$(date +%Y-%m-%d_%H-%M-%S)
ARQUIVO="$BACKUP_DIR/hospital_$DATA.dump"
LOG="$BACKUP_DIR/backup.log"

mkdir -p "$BACKUP_DIR"
echo "[$(date '+%F %T')] Iniciando backup..." >> "$LOG"

# Tratamento de erro: se o pg_dump falhar, apaga o arquivo parcial e sai com erro
if /usr/lib/postgresql/18/bin/pg_dump -Fc "$DATABASE_URL" -f "$ARQUIVO"; then
  echo "[$(date '+%F %T')] OK: $ARQUIVO ($(du -h "$ARQUIVO" | cut -f1))" >> "$LOG"
else
  echo "[$(date '+%F %T')] ERRO: pg_dump falhou" >> "$LOG"
  rm -f "$ARQUIVO"
  exit 1
fi

# Retenção: remove backups com mais de 30 dias
find "$BACKUP_DIR" -name 'hospital_*.dump' -type f -mtime +"$RETENCAO_DIAS" -delete
echo "[$(date '+%F %T')] Limpeza de backups antigos concluída." >> "$LOG"
