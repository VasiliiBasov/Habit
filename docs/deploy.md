# Backend → прод: пошаговый план

Цель: стабильный HTTPS-эндпоинт `https://api.<домен>` для мобильного приложения,
PostgreSQL, безопасные секреты, автоперезапуск, бэкапы.

## Этап 1. Сервер и домен (1–2 часа)

1. Арендовать VPS (минимум 1 vCPU / 1 ГБ RAM): Timeweb Cloud, Selectel, Hetzner (~200–500 ₽/мес). ОС: Ubuntu 24.04.
2. Купить домен (напр., `svoboda-app.ru` или поддомен личного домена). Создать A-запись `api.<домен>` → IP сервера.
3. Подключиться по SSH, создать пользователя, отключить root-вход по паролю, настроить SSH-ключи.

## Этап 2. Окружение на сервере

1. `sudo apt update && sudo apt install -y docker.io docker-compose-v2`
2. Развернуть стек через docker-compose:
   - `postgres:16` (volume `pgdata`)
   - `caddy` (автоматический HTTPS от Let's Encrypt + reverse-proxy на :8080)
   - `app` — образ backend (собирается из Dockerfile, см. ниже)
3. Создать `Dockerfile` в корне backend:

```dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /w
COPY pom.xml .
COPY src ./src
RUN mvn -q package -DskipTests
FROM eclipse-temurin:21-jre
COPY --from=build /w/target/*.jar /app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
```

4. `Caddyfile`: `api.<домен> { reverse_proxy app:8080 }` — TLS поднимется сам по A-записи.

## Этап 3. Конфигурация приложения (секреты через env)

В `.env` рядом с docker-compose (НЕ в git):

```
DB_URL=jdbc:postgresql://postgres:5432/habit
DB_USER=habit
DB_PASSWORD=<сгенерировать, 32+ символа>
DB_DRIVER=org.postgresql.Driver
JWT_SECRET=<сгенерировать, 64+ символа: openssl rand -hex 64>
SPRING_AI_MODEL_CHAT=openai
OPENAI_API_KEY=<ключ LLM-провайдера>
OPENAI_BASE_URL=https://api.openai.com   # или Ollama Cloud / GigaChat-шлюз
OPENAI_MODEL=gpt-4o-mini                  # по вкусу/бюджету
AI_FREE_DAILY_LIMIT=5
REVENUECAT_WEBHOOK_SECRET=<позже при интеграции подписок>
```

`application.yml` уже на это настроен — код менять не нужно, за исключением двух правок:

1. `ddl-auto: update` → `validate` + Flyway-миграции (или добавить профиль `prod`, локально оставить H2).
2. Добавить обработку `HttpRequestMethodNotSupportedException` → 405 (сейчас 500 на GET к POST-эндпоинтам).

## Этап 4. Запуск и проверка

1. `docker compose up -d --build`
2. Проверка: `curl https://api.<домен>/api/auth/register -X POST -H 'Content-Type: application/json' -d '{...}'` → JWT.
3. Проверить HTTPS: браузер, замок, `ssl api.<домен>` (оценка A у SSL Labs).
4. Автоперезапуск: `restart: unless-stopped` в compose.

## Этап 5. Эксплуатация

1. **Бэкапы БД**: cron `pg_dump` → зашифрованный архив → другой диск/облако (ежедневно).
2. Логи: `docker compose logs -f app`; при необходимости — fail2ban для SSH.
3. Мониторинг: UptimeRobot (бесплатно) по `https://api.<домен>/api/auth/register` (достаточно, что отвечает 4xx — сервис жив).

## Этап 6. Переключение приложения

```
flutter build appbundle --release --dart-define=BACKEND_URL=https://api.<домен>
```
Плюс убрать `usesCleartextTraffic="true"` из `app/android/app/src/main/AndroidManifest.xml`.

## Чек-лист «готов к проде»

- [ ] HTTPS по домену, редирект http→https
- [ ] PostgreSQL, данные переживают перезапуск контейнера
- [ ] JWT_SECRET и пароль БД — сильные, только в .env на сервере
- [ ] Бэкапы настроены и проверено восстановление
- [ ] Логин/регистрация/чат/лимит — работают через публичный URL
- [ ] Приложение собрано с прод-URL и работает на физическом телефоне
