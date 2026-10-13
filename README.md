# Habit Backend

Бэкенд мобильного приложения для отказа от вредных привычек с ИИ-помощником.

**Стек:** Java 21 · Spring Boot 4.0.8 · Spring Security + JWT · Spring Data JPA (H2 dev / PostgreSQL prod) · Spring AI 2.0.1 (OpenAI-совместимый API, SSE-стриминг) · RevenueCat webhooks.

## Модули

| Пакет | Ответственность |
|---|---|
| `security` | JWT-фильтр, генерация/валидация токенов, конфигурация Security/CORS |
| `user` | Регистрация, логин, профиль, флаг `premium` |
| `habit` | CRUD привычек, кнопка «Срыв», статистика (счётчик, экономия, достижения) |
| `journal` | Журнал заметок с настроением по каждой привычке |
| `achievement` | Каталог достижений (1д → 1 год), вычисляется из длительности стрика |
| `ai` | ИИ-помощник: контекст привычки, история, стриминг ответа, freemium-лимит |
| `subscription` | Вебхук RevenueCat — вкл/выкл `premium` по событиям подписки |

## Быстрый старт (dev)

```bash
mvn spring-boot:run
```

Приложение поднимется на `:8080` с файловой H2 в `./data/` — никаких внешних зависимостей не нужно.
ИИ-эндпоинт без ключа вернёт `503` — остальное работает сразу.

### Включение ИИ-помощника

```bash
# Windows PowerShell
$env:SPRING_AI_MODEL_CHAT="openai"
$env:OPENAI_API_KEY="sk-..."
mvn spring-boot:run
```

Поддерживается любой OpenAI-совместимый API (в т.ч. российские прокси/GigaChat-совместимые шлюзы) — через `OPENAI_BASE_URL`.

## API

### Auth (публичные)
| Метод | Путь | Описание |
|---|---|---|
| POST | `/api/auth/register` | `{email, password, name}` → `{token, user}` (201) |
| POST | `/api/auth/login` | `{email, password}` → `{token, user}` |
| GET | `/api/auth/me` | профиль + флаг `premium` |

### Привычки (Bearer JWT)
| Метод | Путь | Описание |
|---|---|---|
| GET/POST | `/api/habits` | список / создание |
| PUT/DELETE | `/api/habits/{id}` | обновление / архив |
| POST | `/api/habits/{id}/relapse` | «Срыв» — сброс счётчика (`{note?}`) |
| GET | `/api/habits/{id}/stats` | счётчик (сек), экономия, достижения, следующий уровень |
| GET/POST | `/api/habits/{id}/journal` | журнал |
| DELETE | `/api/journal/{entryId}` | удалить запись |

### ИИ-помощник
| Метод | Путь | Описание |
|---|---|---|
| POST | `/api/ai/chat` | **SSE-стрим** ответа: `{message, habitId?}` → поток `data: <chunk>` |
| GET | `/api/ai/history` | последние 20 сообщений диалога |
| GET | `/api/ai/limit` | `{limit, used}` — freemium-счётчик; для премиум-пользователей 404 |

Лимит для бесплатных: `AI_FREE_DAILY_LIMIT` (по умолчанию 5/сутки), премиум — безлимит.

### Подписки (RevenueCat)
| Метод | Путь | Описание |
|---|---|---|
| POST | `/api/webhooks/revenuecat` | события INITIAL_PURCHASE/RENEWAL/EXPIRATION/... → `premium` |

Во Flutter-клиенте: `Purchases.logIn(email)` — `appUserID` должен совпадать с email аккаунта.

## Конфигурация (env-переменные)

| Переменная | По умолчанию | Назначение |
|---|---|---|
| `JWT_SECRET` | dev-значение | **Обязательно заменить на проде** (base64 ≥ 32 байт) |
| `DB_URL` / `DB_USER` / `DB_PASSWORD` / `DB_DRIVER` | H2 файл | PostgreSQL на проде |
| `SPRING_AI_MODEL_CHAT` | `none` | `openai` — включить ИИ |
| `OPENAI_API_KEY` / `OPENAI_BASE_URL` / `OPENAI_MODEL` | — / api.openai.com / gpt-4o-mini | LLM-провайдер |
| `AI_FREE_DAILY_LIMIT` | 5 | freemium-лимит ИИ-сообщений |
| `REVENUECAT_WEBHOOK_SECRET` | — | секрет вебхука подписок |

## Быстрая проверка из терминала

```bash
# регистрация
curl -X POST http://localhost:8080/api/auth/register -H "Content-Type: application/json" -d '{"email":"a@b.c","password":"secret1","name":"Василий"}'
# создать привычку (подставь токен)
curl -X POST http://localhost:8080/api/habits -H "Authorization: Bearer <TOKEN>" -H "Content-Type: application/json" -d '{"name":"Курение","costPerDay":350,"currency":"RUB"}'
# статистика
curl http://localhost:8080/api/habits/1/stats -H "Authorization: Bearer <TOKEN>"
# стрим ИИ (при включённом SPRING_AI_MODEL_CHAT=openai)
curl -N -X POST http://localhost:8080/api/ai/chat -H "Authorization: Bearer <TOKEN>" -H "Content-Type: application/json" -d '{"message":"Тянет сорваться, что делать?","habitId":1}'
```

## Дорожная карта до прода

- [ ] Перевести схему на Flyway-миграции + `ddl-auto: validate`, поднять PostgreSQL
- [ ] Rate limiting на `/api/ai/chat` (bucket4j) помимо дневного лимита
- [ ] Push-напоминания через FCM (endpoint регистрации device token)
- [ ] Сузить CORS, ротация JWT (refresh-токены)
- [ ] Нагрузочные тесты стрима, мониторинг стоимости ИИ-запросов
- [ ] Деплой (Docker), CI/CD
