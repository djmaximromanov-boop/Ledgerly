# Модули и чаты

A — Ядро; B — Финансовый учёт; C — Аналитика и планирование; D — Настройки и безопасность.
Группы логические, не вложенные папки ChatGPT.

## A · 00 — Каркас и архитектура

Навигация, модель Core Data, инфраструктура, дизайн, интеграция Git и архитектурные решения.

Исходники: `LedgerlyApp.swift, ContentView.swift, Persistence/, project.yml` (относительно Ledgerly/).

## B · 01 — Счета и балансы

Счета, наличные, карты, валюты, остатки и переводы. Согласовывать операции с 02.

Исходники: `Models/CoreData/Account+CoreData.swift, Book+CoreData.swift` (относительно Ledgerly/).

## B · 02 — Доходы и расходы

Операции, категории, история, регулярные платежи. Единственная общая семантика операций.

Исходники: `ViewModels/TransactionViewModel.swift, CategoryViewModel.swift, Views/Tabs/QuickEntryView.swift, BillListView.swift` (относительно Ledgerly/).

## C · 03 — Аналитика

Отчёты, графики, периоды, категории, прибыль направлений. Читать общие операции 02 и счета 01.

Исходники: `ViewModels/StatisticsViewModel.swift, Views/Tabs/StatisticsView.swift, Views/Charts/` (относительно Ledgerly/).

## B · 04 — Долги и кредиты

Долги, займы, проценты и графики погашения. Отдельной модели пока нет; спроектировать с 00/01/02.

Исходники: `Новая функциональность поверх общей модели Ledgerly; не отдельное приложение` (относительно Ledgerly/).

## C · 05 — Бюджеты и цели

Лимиты, бюджеты, накопления и планирование. Не смешивать Budget с отсутствующей моделью целей.

Исходники: `ViewModels/BudgetViewModel.swift, Models/CoreData/Budget+CoreData.swift, Views/Components/BudgetProgressView.swift` (относительно Ledgerly/).

## D · 06 — Настройки и защита

Настройки, русский язык, темы, Face ID, экспорт, резервные копии, iCloud. Проверять каждую возможность.

Исходники: `Views/Tabs/SettingsView.swift, Services/, Ledgerly.entitlements` (относительно Ledgerly/).
