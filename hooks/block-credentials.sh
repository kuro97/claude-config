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

# Разделитель приводим к прямому слэшу: из JSON путь приходит как
# d:\\proj\\tests\\x.py, и любая маска со слэшем (*/tests/*, */.env*)
# по нему не срабатывает. Без этого исключения ниже молча не работали бы
# на Windows — а это единственная система, где хук и используется.
lower=$(printf '%s' "$path" | tr '[:upper:]' '[:lower:]' | tr '\\' '/')

# Шаблоны без секретов — править можно.
case "$lower" in
  *.env.example*|*.env.sample*|*.env.template*|*.env.dist*) exit 0 ;;
esac

block() {
  echo "BLOCKED: $path — файл с credentials, правка запрещена (правило в CLAUDE.md)." >&2
  echo "Если правка действительно нужна — сделай её сам, руками." >&2
  exit 2
}

# Секрет всегда, где бы ни лежал — включая тестовые каталоги. Раньше исключение
# для тестов стояло выше блок-листа и открывало tests/.env и fixtures/*.pem:
# именно те файлы, ради которых хук и написан. Фикстуры этих типов почти не
# встречаются, а .env и приватные ключи внутри tests/ — встречаются, и они
# настоящие. Проверено 2026-08-10.
case "$lower" in
  *.env|*.env.*|*.env\ *|*/.env*|\
  *.pem|*.p12|*.pfx|*id_rsa*|*id_ed25519*|*.pgpass|*.npmrc|*.my.cnf)
    block ;;
esac

# Ниже — маски, которые ловят по ИМЕНИ и потому дают ложные срабатывания:
# *config.py поймала tests/test_aiplus_config.py, и правка теста упёрлась
# в запрет (aiplus-AI-digest, 2026-08-04). Только для них исключение на тесты:
# json-фикстуры с выдуманными токенами живут в tests/ и fixtures/ — это норма.
case "$lower" in
  */tests/*|*/test/*|*/test_*|*_test.py|*_test.go|*_test.js|\
  *.test.*|*.spec.*|*/spec/*|*/__tests__/*|*/fixtures/*)
    exit 0 ;;
esac

case "$lower" in
  *keys.json*|*credentials.json*|*secrets.json*|\
  *service-account*.json|*token.json)
    block ;;
esac

# config.py / config.php — по имени не судить: почти везде это обычный модуль настроек
# на os.getenv/env(), секреты в нём не лежат. Блокировать только если внутри реально
# присвоен литеральный секрет (в PHP-проектах пароль в Config.php — обычное дело).
# Ключ может стоять в кавычках: "db_password" => "…" (PHP-массивы, dict в Python).
case "$lower" in
  *config.php|*config.py)
    [ -f "$path" ] || exit 0   # нового файла ещё нет — проверять нечего
    if grep -qiE '(pass(w(or)?d)?|secret|token|api_?key|[^a-z_]key|dsn)["'"'"']?[[:space:]]*(=|=>|:)[[:space:]]*["'"'"'][^"'"'"']{12,}' "$path"; then
      echo "BLOCKED: $path — внутри литеральный секрет, правка запрещена (правило в CLAUDE.md)." >&2
      echo "Если правка действительно нужна — сделай её сам, руками." >&2
      exit 2
    fi
    exit 0
    ;;
esac

exit 0
