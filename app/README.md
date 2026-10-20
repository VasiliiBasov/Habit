## Быстрый запуск (dev)

```powershell
powershell -ExecutionPolicy Bypass -File scripts/dev.ps1
```

Скрипт поднимает Spring Boot бэкенд из `..\Habit\target` (если не запущен)
и открывает приложение в Edge с `BACKEND_URL=http://localhost:8080`.

### Вариант: Android-эмулятор

```powershell
powershell -ExecutionPolicy Bypass -File scripts/dev.ps1 -Android
```

Поднимает AVD `habit_pixel` (Pixel 6, API 35, Play Store — создаётся
`C:\src\android-setup.ps1`), ждёт загрузки и ставит debug-сборку с
`BACKEND_URL=http://10.0.2.2:8080` (localhost хоста для эмулятора).
Первая сборка занимает ~15 мин: Gradle докачивает SDK Platform 35,
NDK и CMake — это нормально, прогресс виден в логе.



Windows-desktop-сборка требует Visual Studio с C++ toolchain (не установлена).
Тестовый пользователь (создан smoke-тестом): `smoke@test.dev` / `smoketest123` —
внутри уже есть привычка «Сигареты» с живым таймером.


# Habit App — Flutter-клиент

Мобильное приложение «Свобода от привычек»: счётчик трезвости, экономия денег,
достижения, журнал и ИИ-помощник. Бэкенд — Spring Boot 4 в проекте
`../Habit` (должен быть запущен).

## Требования

- Flutter SDK 3.47.x (stable) — установлен в `C:\src\flutter`, добавлен в PATH
- Запущенный бэкенд: `cd ../Habit && mvn spring-boot:run`

## Запуск

```powershell
cd C:\Users\Vasilii\IdeaProjects\habit_app
flutter pub get

# Android-эмулятор (localhost хоста = 10.0.2.2, это значение по умолчанию):
flutter run -d emulator-5554

# Windows-десктоп или физическое устройство в той же сети:
flutter run -d windows --dart-define=BACKEND_URL=http://localhost:8080
```

## Структура

```
lib/
  main.dart                      # точка входа: DI + восстановление сессии
  app.dart                       # роутер (go_router) + провайдеры (flutter_bloc)
  core/
    config/app_config.dart       # BACKEND_URL через --dart-define
    network/api_client.dart      # dio + Bearer-интерсептор + маппинг ошибок
    network/sse_client.dart      # потоковый SSE-парсер (покрыт тестами)
    storage/token_storage.dart   # JWT в secure storage
  features/
    auth/                        # логин/регистрация, AuthCubit
    habits/                      # список, создание, деталь: таймер+деньги+достижения, срыв
    journal/                     # записи с настроением (вкладка на экране привычки)
    chat/                        # ИИ-чат, SSE-стрим ответа, freemium-лимит
    home/                        # нижняя навигация
    settings/                    # аккаунт, премиум-заглушка, выход
```

## Как это связано с бэкендом

| Экран | API |
|---|---|
| Вход/регистрация | `POST /api/auth/login`, `/register`, `GET /api/auth/me` |
| Привычки | `GET/POST /api/habits`, `PUT/DELETE /api/habits/{id}` |
| Деталь | `GET /api/habits/{id}/stats`, `POST /{id}/relapse` |
| Журнал | `GET/POST /api/habits/{id}/journal` |
| Чат | `POST /api/ai/chat` (SSE), `GET /api/ai/history/{id}`, `GET /api/ai/limit` |

## Что дальше (монетизация)

1. **RevenueCat**: `purchases_flutter`, `Purchases.logIn(email)` после login,
   paywall-экран вместо заглушки в чате, вебхук уже принимает бэкенд.
2. **AdMob**: `google_mobile_ads` — баннер/interstitial для Free-пользователей.
3. **FCM** push-напоминания («держитесь, уже N дней!»).

## Тесты

```powershell
flutter test
```
