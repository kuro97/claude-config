# Claude Code Config — Единый источник правды

Глобальные правила, субагенты и скиллы — общие для всех моих проектов.

## Структура

```
claude-config/
├── CLAUDE.md            # Глобальные правила (язык, brainstorming first, одобрение, роутинг моделей)
├── sync.sh              # Синхронизация → ~/.claude/ (CLAUDE.md + skills/ + agents/)
├── README.md            # Этот файл
├── agents/              # Субагенты Claude Code (модель + effort в frontmatter)
│   ├── architect.md     #   Fable 5.1 / xhigh — системная архитектура (ЕДИНСТВЕННАЯ точка Fable), read-only
│   ├── researcher.md    #   Sonnet 5 / medium — исследование кодовой базы/веба, read-only
│   └── mechanic.md      #   Haiku 4.5 / low — механика: grep/поиск/переименования/форматирование
├── hooks/               # Хуки Claude Code (НЕ синхронизируются — путь прописан в settings.json)
│   ├── block-credentials.sh  #   PreToolUse(Edit|Write): блок правки .env/ключей/config.py — вторая линия к правилу в CLAUDE.md
│   └── notify.ps1       #   Уведомления
├── statusline/
│   └── statusline.sh    # Статус-строка: модель сессии + режим architect + лимит 5h (jq-free, вкл. вручную)
└── skills/
    │
    │  # Основные (свои)
    ├── brainstorming/                  # Мозговой штурм (обязательно первое сообщение)
    ├── build/                          # Оркестратор разработки (модель на каждый этап, не кодит сам)
    ├── plan/                           # Сбор инфо + план → верификация Fable (research→черновик→architect)
    ├── research/                       # Исследование кода
    ├── deep-research/                  # Глубокий веб-ресёрч (4 режима)
    ├── review/                         # Ревью перед деплоем
    ├── docs/                           # Генерация документации
    ├── report/                         # Итоговые отчёты
    ├── task-status/                    # Статус задачи чек-листом: готово / не проверено / дальше по порядку / блокеры
    ├── test/                           # Написание тестов
    ├── tz/                             # Создание технического задания
    ├── simplify-this/                  # Радикальное упрощение спек/архитектур (assess/proposal/rewrite)
    ├── audit-server/                   # Аудит продакшн-сервера (SSH, чек-лист, бэкап)
    ├── spec-to-code/                   # TDD-пайплайн: ТЗ → тесты → код → /review
    │
    │  # Роутинг моделей
    ├── fable-off/                      # architect: Fable → Opus (фолбэк) + sync
    ├── fable-on/                       # architect: Opus → Fable (возврат) + sync
    │
    │  # Аудит и качество кода
    ├── api-contract-guardian/          # Проверка API контрактов и схем
    ├── cicd-quick-setup/               # Готовый деплой-пайплайн под стек
    ├── dependency-optimizer/           # Аудит зависимостей (CVE, мусор, тяжёлые)
    ├── error-handling-standardizer/    # Единая обработка ошибок и логирование
    ├── performance-scanner/            # Узкие места и медленные операции
    │
    │  # Superpowers [SP]
    ├── systematic-debugging/           # [SP] 4-фазный дебаг
    ├── test-driven-development/        # [SP] RED-GREEN-REFACTOR
    ├── verification-before-completion/ # [SP] Проверка "готово"
    ├── subagent-driven-development/    # [SP] Субагенты + 2-stage review
    ├── dispatching-parallel-agents/    # [SP] Параллельные субагенты
    ├── receiving-code-review/          # [SP] Приём фидбека от ревью
    ├── finishing-a-development-branch/ # [SP] Merge/PR/cleanup
    ├── using-git-worktrees/            # [SP] Изоляция через worktree
    │
    │  # База данных (PostgreSQL под AiPlus)
    ├── postgres-patterns/              # Индексы, пагинация, очереди Watermill, multi-schema
    ├── database-reviewer/              # Ревью SQL/схем/миграций (read-only, file:line)
    ├── database-migrations/            # Zero-downtime миграции (Goose, expand-contract)
    │
    │  # Обслуживание сетапа (ревизоры — только отчёт)
    ├── skill-stocktake/                # Ревизия скиллов: дубли, качество, вердикты
    ├── context-budget/                 # Аудит токен-бюджета (CLAUDE.md/скиллы/MCP)
    └── rules-distill/                  # Принципы из 2+ скиллов → правила
```

## Роутинг моделей

Задачи распределяются по моделям автоматически. 📖 **Гайд для команды (как повторить у себя) — [`MODEL-ROUTING.md`](MODEL-ROUTING.md).** Полная карта «тип задачи → модель» — в `CLAUDE.md`, секция **«Роутинг моделей по задачам»**. Кратко:

- **Две оси**: модель × **effort**. Глобальный effort — `xhigh` (`effortLevel` в `~/.claude/settings.json`); безопасно, потому что у субагентов свой effort во frontmatter — механика и research на xhigh не идут.
- **Субагенты** (`agents/`) несут модель и effort в frontmatter: `architect`=Fable 5.1/xhigh (только системная архитектура — единственная точка Fable; алиас `fable` резолвится в текущую версию), `researcher`=Sonnet 5/medium, `mechanic`=Haiku 4.5/low.
- **Главный цикл** — Opus 5 по умолчанию; всё, чего нет в карте → Opus 5.
- **Скиллы**: worker-скиллы низкой ставки пиннятся `model: sonnet` (docs, report, test, deep-research, dependency-optimizer, cicd-quick-setup, error-handling-standardizer, context-budget, skill-stocktake, research, api-contract-guardian); `review`→opus; `audit-server`→`claude-opus-4-8`; `fable-off/on`→haiku. Оркестраторы (`build`, `plan`, `spec-to-code`, `subagent-driven-development`, `dispatching-parallel-agents`) и дисциплины (`systematic-debugging`, TDD, verification, `task-status`) без пина — едут на дефолтном Opus 5. У `task-status` пин был бы вреден отдельно: `model` в скилле действует до конца turn'а, а сверка доказательств «сделано / не проверено» — не то место, где экономят.
- **Классификаторы**: Opus 5 и Fable 5.x несут cyber/bio-фильтры, харнесс сам делает content-fallback (Fable 5: cyber→Opus 4.8, bio→Opus 5; Opus 5: cyber→Opus 4.8; цели для Fable 5.1 не сверены, по косвенным признакам та же пара Fable→Opus 4.8). Фолбэк переводит всю сессию — на pentest/аудитах стартовать `/model claude-opus-4-8` заранее.
- **Фолбэк Fable→Opus**: refusal ловит харнесс сам; `/fable-off` остаётся клапаном по недельной квоте (Fable capped 50% на Team Premium), возврат — `/fable-on`. Правят исходник `agents/architect.md` + запускают `sync.sh`.
- **statusline** (опц.): показывает текущую модель сессии + режим architect + лимит 5h. Включить — прописать `statusLine` в `~/.claude/settings.json` (пример — в шапке `statusline/statusline.sh`).

## Как использовать

### Первая настройка (на новой машине)
```bash
git clone git@github.com:asistentkz/claude-config.git D:/claude/claude-config
cd D:/claude/claude-config
bash sync.sh
```

### Обновление
1. Отредактировать файлы в `claude-config/`
2. Запустить `bash sync.sh`
3. Закоммитить и запушить: `git add <файлы> && git commit -m "..." && git push`

### `git pull` падает с расхождением истории — что делать

**10.08.2026 история была перезаписана один раз.** Из сообщения одного коммита убрали IP сервера и путь к файлу с токеном — репозиторий публичный, и такие данные в нём не нужны. Переписаны **только сообщения**, содержимое файлов не менялось ни в одном коммите. Но SHA у этого коммита и всех шести поверх него сменились, поэтому обычный `pull` выдаст:

```
fatal: refusing to merge unrelated histories
# или: hint: You have divergent branches
```

Ничего не сломалось — надо просто перевести свой клон на новую историю.

**Если ты только тянешь обновления и своих правок не делал** — самый простой путь:

```bash
git fetch origin
git reset --hard origin/main
bash sync.sh                  # обязательно: перелить скиллы и правила в ~/.claude/
```

**Если есть незакоммиченные правки** — сначала спрятать, потом вернуть:

```bash
git stash
git fetch origin
git reset --hard origin/main
git stash pop                 # конфликтов быть не должно: файлы не менялись
bash sync.sh
```

**Если есть свои коммиты, которых нет в origin** — не терять их, а перенести:

```bash
git branch my-work            # закладка на свои коммиты
git fetch origin
git reset --hard origin/main
git cherry-pick <sha>         # по одному из my-work, снизу вверх
git branch -D my-work         # когда всё перенесено
bash sync.sh
```

Посмотреть свои коммиты перед переносом: `git log origin/main..my-work --oneline`.

`git reset --hard` затирает незакоммиченное — если не уверен, что спрятал всё, сначала `git status`.

## Что куда синхронизируется

`sync.sh` копирует **только в `~/.claude/`** (глобальные настройки, работают во всех проектах):

| Источник | Куда | Режим |
|----------|------|-------|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | перезапись |
| `skills/*` | `~/.claude/skills/*` | перезапись SKILL.md |
| `agents/*` | `~/.claude/agents/*` | **full-replace** (папка чистится перед копированием — призраков удалённых агентов не остаётся) |

## Что НЕ синхронизируется

- **Проектные `CLAUDE.md`** — специфичны для каждого проекта (стек, порты, интеграции)
- **Стек-специфичные скиллы** — `golang-patterns`, `golang-testing`, `dart-flutter-patterns`, `flutter-dart-code-review` живут локально в проекте (vault) и в git не отправляются
- **`settings.json`** — permissions и хуки специфичны для каждой машины
- **`statusline/`** — не копируется; статус-строка запускается напрямую из claude-config (путь прописан в `settings.json`). `statusline.sh` — jq-free (jq в Git Bash на Windows нет)
- **`hooks/`** — не копируется по той же схеме: `settings.json` ссылается на скрипт прямо в claude-config, поэтому **рабочее дерево и есть живой хук** — незакоммиченная правка уже действует. На новой машине хук молча не заработает, пока путь не прописан в `settings.json`. `block-credentials.sh` тоже jq-free: версия на `jq` получала пустую строку и пропускала всё через `exit 0`

## Правила

- Глобальные правила — в этом репо
- Проектные правила — в проектном `CLAUDE.md`
- **Один источник правды** — менять здесь, синхронизировать скриптом, коммитить и пушить
```
