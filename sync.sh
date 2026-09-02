#!/bin/bash
set -euo pipefail

# ============================================
# Claude Code Config Sync
# Единый источник правды → глобальные настройки
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GLOBAL_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

if [ -z "$GLOBAL_DIR" ] || [ "$GLOBAL_DIR" = "/" ] || [ "$GLOBAL_DIR" = "." ]; then
  echo "Ошибка: небезопасный путь глобальной конфигурации: '$GLOBAL_DIR'" >&2
  exit 1
fi

mkdir -p "$GLOBAL_DIR"
GLOBAL_DIR="$(cd "$GLOBAL_DIR" && pwd -P)"

if [ "$(basename "$GLOBAL_DIR")" != ".claude" ]; then
  echo "Ошибка: каталог глобальной конфигурации должен называться .claude: '$GLOBAL_DIR'" >&2
  exit 1
fi

echo "========================================"
echo "  Claude Code Config Sync"
echo "  Источник: $SCRIPT_DIR"
echo "========================================"
echo ""

# --- 1. Синхронизация глобальных ---
echo "[1/2] Глобальные настройки (~/.claude/) ..."

# CLAUDE.md
cp "$SCRIPT_DIR/CLAUDE.md" "$GLOBAL_DIR/CLAUDE.md"
echo "  ✓ CLAUDE.md → ~/.claude/"

# Локальные списки-исключения (лежат вне репозитория, у каждой машины свои):
#   ~/.claude/.sync-ignore — имена скиллов, которые НЕ тянуть из репозитория
#   ~/.claude/.sync-keep   — имена агентов, которых НЕ удалять при full-replace
IGNORE_FILE="$GLOBAL_DIR/.sync-ignore"
KEEP_FILE="$GLOBAL_DIR/.sync-keep"

is_listed() {
  # $1 — имя, $2 — путь к файлу списка
  [ -f "$2" ] || return 1
  grep -qxF "$1" <(grep -vE '^\s*(#|$)' "$2") 2>/dev/null
}

# Skills
skill_count=0
skill_skipped=0
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
  skill_name=$(basename "$skill_dir")
  if is_listed "$skill_name" "$IGNORE_FILE"; then
    echo "  – /skills/$skill_name/ (пропущен: .sync-ignore)"
    skill_skipped=$((skill_skipped + 1))
    continue
  fi
  mkdir -p "$GLOBAL_DIR/skills/$skill_name"
  cp "$skill_dir"SKILL.md "$GLOBAL_DIR/skills/$skill_name/SKILL.md"
  echo "  ✓ /skills/$skill_name/"
  skill_count=$((skill_count + 1))
done

echo ""

# --- Субагенты (~/.claude/agents/) ---
# Репозиторий владеет своими агентами: переименованный/удалённый агент не должен
# оставить «призрака» в глобале. Но локальные агенты, которых в репозитории нет,
# удаляются только если не перечислены в ~/.claude/.sync-keep.
echo "  Субагенты (~/.claude/agents/) ..."
SOURCE_AGENTS_DIR="$SCRIPT_DIR/agents"
TARGET_AGENTS_DIR="$GLOBAL_DIR/agents"

# Не очищаем глобальных агентов, если источник отсутствует или пуст.
if [ ! -d "$SOURCE_AGENTS_DIR" ] || ! compgen -G "$SOURCE_AGENTS_DIR/*.md" >/dev/null; then
  echo "Ошибка: в $SOURCE_AGENTS_DIR не найдены файлы агентов; full-replace отменён." >&2
  exit 1
fi

if [ "$TARGET_AGENTS_DIR" != "$GLOBAL_DIR/agents" ] \
  || [ "$TARGET_AGENTS_DIR" = "$HOME" ] \
  || [ "$TARGET_AGENTS_DIR" = "/" ] \
  || [ "$TARGET_AGENTS_DIR" = "/agents" ]; then
  echo "Ошибка: небезопасный путь назначения агентов: '$TARGET_AGENTS_DIR'" >&2
  exit 1
fi

mkdir -p "$TARGET_AGENTS_DIR"

# Точечная уборка вместо rm -rf всей папки: удаляем только тех агентов, которых
# нет ни в репозитории, ни в .sync-keep. Прежний rm -rf уносил локальных агентов молча.
agent_removed=0
agent_kept=0
if compgen -G "$TARGET_AGENTS_DIR/*.md" >/dev/null; then
  for existing in "$TARGET_AGENTS_DIR"/*.md; do
    name=$(basename "$existing")
    [ -f "$SOURCE_AGENTS_DIR/$name" ] && continue
    if is_listed "${name%.md}" "$KEEP_FILE" || is_listed "$name" "$KEEP_FILE"; then
      echo "  – /agents/$name (сохранён: .sync-keep)"
      agent_kept=$((agent_kept + 1))
      continue
    fi
    rm -f "$existing"
    echo "  ✗ /agents/$name (удалён: нет в репозитории и не в .sync-keep)"
    agent_removed=$((agent_removed + 1))
  done
fi

agent_count=0
for agent_file in "$SOURCE_AGENTS_DIR"/*.md; do
  cp "$agent_file" "$TARGET_AGENTS_DIR/"
  echo "  ✓ /agents/$(basename "$agent_file")"
  agent_count=$((agent_count + 1))
done

echo ""

# --- 2. Итог ---
echo "[2/2] Готово!"
echo ""
echo "Синхронизировано:"
echo "  • CLAUDE.md (глобальные правила)"
echo "  • $skill_count скиллов → ~/.claude/skills/"
echo "  • $agent_count субагентов → ~/.claude/agents/"
[ "$skill_skipped" -gt 0 ] && echo "  • пропущено скиллов (.sync-ignore): $skill_skipped"
[ "$agent_kept" -gt 0 ] && echo "  • сохранено локальных агентов (.sync-keep): $agent_kept"
[ "$agent_removed" -gt 0 ] && echo "  • удалено агентов-призраков: $agent_removed"
echo ""
echo "НЕ синхронизируется (личный слой, живёт только на этой машине):"
echo "  ~/.claude/rules/, ~/.claude/scripts/, ~/.claude/commands/, ~/.claude/settings.json"
echo "  Бэкап личного слоя: bash ~/.claude/scripts/backup-config.sh"
echo ""
echo "Примечание: проектные CLAUDE.md НЕ перезаписываются."
echo "Стек-специфичные скиллы (security, sql-audit, migrate-check и др.) — в проектах."
echo "========================================"
