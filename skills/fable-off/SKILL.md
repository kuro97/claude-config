---
name: fable-off
description: Переключить агента architect с Fable на Opus — клапан по недельной квоте (на Team Premium Fable упирается в 50% лимита) или когда Fable недоступна. Content-refusal харнесс обрабатывает сам, для этого скилл не нужен. Правит исходник в claude-config и запускает sync.
allowed-tools: Read, Edit, Bash
model: haiku
---

Переброс architect: Fable → Opus.

Выполни:
1. В файле `D:/claude/claude-config/agents/architect.md` замени строку frontmatter `model: fable` на `model: opus`. Если там уже `model: opus` — сообщи, что фолбэк уже активен, и остановись.
2. Запусти синк: `bash D:/claude/claude-config/sync.sh`
3. Подтверди пользователю: «architect переведён на Opus (Fable-фолбэк активен). Вернуть — /fable-on.»

ВАЖНО: правим ИСХОДНИК в claude-config (не глобал ~/.claude), иначе следующий sync откатит изменение обратно на Fable.
