#!/bin/bash
# PreToolUse hook (Edit|Write): запрет правки файлов с секретами.
#
# ВАЖНО: jq-free. В Git Bash на Windows jq НЕТ — предыдущая версия этого хука
# парсила payload через jq, получала пустую строку и молча пропускала всё
# (exit 0). Проверено 2026-07-30: `command -v jq` → not found.
# Разбор только grep/sed, как в statusline/statusline.sh.
#
# Контракт: payload тула приходит JSON-ом на stdin, вернуть exit 2 = заблокировать.
# Это ВТОРАЯ линия — первая живёт правилом в CLAUDE.md, потому что хук
# не видит записи через Bash (sed -i, >>, tee).

payload=$(cat)

# "file_path": "..." → путь. Windows-пути в JSON приходят с \\ — для сравнения
# по маскам это неважно.
path=$(printf '%s' "$payload" \
  | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | head -1 \
  | sed 's/^.*:[[:space:]]*"//; s/"$//')

if [ -z "$path" ]; then
  # Не молчать: если парсинг сломался, это должно быть видно, а не выглядеть как «проверка прошла».
  if [ -n "$payload" ]; then
    echo "hook block-credentials: не удалось извлечь file_path из payload — проверка НЕ выполнена" >&2
  fi
  exit 0
fi

lower=$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]')

# Шаблоны без секретов — править можно.
case "$lower" in
  *.env.example*|*.env.sample*|*.env.template*|*.env.dist*) exit 0 ;;
esac

case "$lower" in
  *.env|*.env.*|*.env\ *|*/.env*|*keys.json*|*credentials.json*|*secrets.json*|\
  *config.php|*config.py|*service-account*.json|*token.json|\
  *.pem|*.p12|*.pfx|*id_rsa*|*id_ed25519*|*.npmrc|*.pgpass|*.my.cnf)
    echo "BLOCKED: $path — файл с credentials, правка запрещена (правило в CLAUDE.md)." >&2
    echo "Если правка действительно нужна — сделай её сам, руками." >&2
    exit 2
    ;;
esac

exit 0
