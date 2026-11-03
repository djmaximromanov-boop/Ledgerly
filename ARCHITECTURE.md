# Архитектура

## Фактическая структура Ledgerly

`Ledgerly/LedgerlyApp.swift` → `ContentView.swift` → пять вкладок:
QuickEntryView, BillListView, StatisticsView, BookManagementView, SettingsView.
ViewModels: Book, Transaction, Category, Budget, Statistics.
Хранилище: `Persistence/PersistenceController.swift`, `CoreDataStack.swift`.
Модель: `Models/CoreData/Ledgerly.xcdatamodeld` и классы Book, Account,
Transaction, Category, Member, Budget, SplitRecord.
Сервисы: CloudKitService, SharingService, ArchiveService, NotificationService,
LocalizationManager. Общие UI-компоненты и Extensions используются совместно.

## Правила доработки

Модули — границы ответственности, а не семь независимых приложений или Swift packages.
Пока не перемещать исходники только ради соответствия названиям чатов.
Модуль 00 ведёт навигацию, модель данных, инфраструктуру и общие решения.
Модуль 02 отвечает за семантику операций; 01 — остатки; 03 и 05 используют
общие операции. Модуль 04 согласует погашения с 01/02, чтобы не удваивать расходы.
06 отвечает за настройки, локализацию, защиту и восстановление.

Денежные расчёты вести в Decimal/NSDecimalNumber с явной валютой и округлением.
Не менять хранилище без плана миграции и проверки сохранённых данных.
Переводы не считать доходом/расходом в общей аналитике. Это целевое правило,
его ещё нужно реализовать в существующей модели.
Не добавлять отдельную базу или копии общих моделей для каждого чата.
Факт наличия CloudKitService не доказывает работающий обмен данными.
