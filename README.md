# MORE Finance — проект «Бюджет»

Доработка [Ledgerly](https://github.com/DMLayMan/Ledgerly), не новое приложение с нуля.
Исходный README сохранён в [README_UPSTREAM.md](README_UPSTREAM.md).
MIT LICENSE и copyright Ledgerly Contributors сохранены без изменений.

## Единая рабочая копия

`/Users/wannamore/Documents/ChatGPT/Бюджет/Ledgerly`

Читайте [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md), [ARCHITECTURE.md](ARCHITECTURE.md),
[MODULES.md](MODULES.md), [CHANGE_PROTOCOL.md](CHANGE_PROTOCOL.md).
Git хранит код и решения; сообщения чатов не синхронизируются автоматически.
Загруженные в ChatGPT документы — снимки, их нужно обновлять после изменений.
Рабочий GitHub: https://github.com/djmaximromanov-boop/Ledgerly (origin).
Оригинал DMLayMan/Ledgerly — upstream; не отправлять в него изменения напрямую.

## Открытие и проверка

Откройте `Ledgerly.xcodeproj` в установленном Xcode. Существующий проект уже включён;
XcodeGen нужен при изменении `project.yml`, а не для первого открытия.
Минимальная цель в конфигурации: iOS 17, Swift 5.9. Название target пока Ledgerly.
Пошаговая установка на личный iPhone 16e описана в [INSTALL_IOS.md](INSTALL_IOS.md).

Проверка без подписи:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Ledgerly.xcodeproj -scheme Ledgerly -sdk iphonesimulator -configuration Debug -derivedDataPath /tmp/more-finance-build CODE_SIGNING_ALLOWED=NO build
```

Обычная сборка хранит данные локально и не запрашивает платный CloudKit. Для установки
через Xcode нужно указать личную команду подписи и уникальный bundle ID. CloudKit
можно включить отдельно; требования и шаги описаны в `INSTALL_IOS.md`.
Существующий `run_device.sh` не запускался. Не считать iCloud, экспорт и миграции
проверенными по одному наличию исходников. Результаты проверок: [VALIDATION.md](VALIDATION.md).
