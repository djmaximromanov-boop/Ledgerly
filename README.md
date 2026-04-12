<p align="center">
  <h1 align="center">Ledgerly</h1>
  <p align="center">
    <strong>Your money. Your data. Your rules.</strong>
  </p>
  <p align="center">
    <a href="https://github.com/DMLayMan/Ledgerly/blob/main/LICENSE"><img src="https://img.shields.io/github/license/DMLayMan/Ledgerly?color=blue" alt="License"></a>
    <a href="https://github.com/DMLayMan/Ledgerly/issues"><img src="https://img.shields.io/github/issues/DMLayMan/Ledgerly" alt="Issues"></a>
    <a href="https://github.com/DMLayMan/Ledgerly/pulls"><img src="https://img.shields.io/github/issues-pr/DMLayMan/Ledgerly" alt="Pull Requests"></a>
    <img src="https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey" alt="Platform">
    <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift">
    <img src="https://img.shields.io/badge/dependencies-zero-green" alt="Dependencies">
  </p>
</p>

---

Ledgerly is an open-source iOS expense tracker built with SwiftUI. It supports personal and shared ledger management, budget tracking, and rich statistical insights — all powered by Core Data + CloudKit with **zero third-party dependencies**.

## ✨ Features

- **Quick Entry** — Custom calculator keyboard with expression support (+, -, ×), two-level category grid, expense/income toggle
- **Bill Management** — Monthly filtering, search, daily grouping, swipe-to-delete
- **Statistics** — Trend charts (line + area), category pie charts, member comparison (shared ledgers), weekly/monthly/yearly views
- **Ledger Management** — Personal & shared ledgers, icon selection, ledger switching
- **Budget Tracking** — Monthly/yearly budgets, gradient progress bars, overrun alerts
- **Category System** — 10 expense + 4 income preset categories with subcategories, custom categories, drag-to-sort
- **Shared Ledgers** — iCloud-based sharing via CloudKit CKShare, member roles (owner/editor/viewer)
- **Bill Splitting** — Equal split or custom ratio, per-member share calculation
- **Data Export** — CSV and JSON export with share sheet
- **iCloud Sync** — Automatic sync via NSPersistentCloudKitContainer
- **Data Archiving** — Auto-archive records older than 6 months or exceeding 10,000 entries
- **Notifications** — Budget overrun alerts, daily recording reminders
- **Localization** — In-app language switching (English / 简体中文), extensible for more languages

## 🛠 Tech Stack

| Component | Technology |
|---|---|
| UI | SwiftUI |
| Persistence | Core Data + NSPersistentCloudKitContainer |
| Cloud Sync | CloudKit (Private + Shared Database) |
| Charts | SwiftUI Charts (iOS 16+) |
| Notifications | UserNotifications |
| Build | XcodeGen (project.yml) |
| Language | Swift 5.9 |
| Minimum iOS | 17.0 |

**Zero third-party dependencies.**

## 📁 Project Structure

```
Ledgerly/
├── LedgerlyApp.swift              # App entry
├── ContentView.swift              # TabView container
├── Models/
│   ├── CoreData/                  # Core Data entities + extensions
│   └── Enums/                     # Type enums (BookType, TransactionType, etc.)
├── Persistence/                   # PersistenceController + CoreDataStack
├── ViewModels/                    # MVVM ViewModels
├── Views/
│   ├── Tabs/                      # Main tab views
│   ├── Components/                # Reusable UI components
│   ├── Charts/                    # Chart views
│   └── Sharing/                   # Sharing & member management
├── Services/                      # CloudKit, Notifications, Archive, Localization
├── Extensions/                    # Color theme, Date helpers, Decimal formatting
└── Resources/                     # Asset catalog
```

## 🚀 Getting Started

### Prerequisites

- Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build & Run

```bash
# Clone the repository
git clone https://github.com/DMLayMan/Ledgerly.git
cd Ledgerly

# Generate Xcode project
xcodegen generate

# Open in Xcode
open Ledgerly.xcodeproj
```

### Run on Simulator (CLI)

```bash
# Build and launch on simulator
./run_device.sh --simulator
```

### Run on Real Device

```bash
# Build and install on connected iPhone
./run_device.sh --device
```

> Requires a valid Apple Developer signing identity. The script will guide you through setup if needed.

### iCloud Configuration

To enable CloudKit sync and shared ledgers:

1. Set your **Development Team** in Xcode project settings
2. Update the iCloud container identifier in `Ledgerly/Ledgerly.entitlements` and `project.yml` to match your Apple Developer account
3. Ensure the CloudKit container is created in the [CloudKit Console](https://icloud.developer.apple.com/)

> On the Simulator, CloudKit sync is automatically disabled for development convenience.

## 🏗 Architecture

```
LedgerlyApp (Entry)
  └─ ContentView (TabView)
       ├─ QuickEntryView      (Record)
       ├─ BillListView        (Bills)
       ├─ StatisticsView      (Stats)
       ├─ BookManagementView  (Ledgers)
       └─ SettingsView        (Settings)

Pattern: MVVM
Persistence: Core Data + NSPersistentCloudKitContainer
Sync: CloudKit (Private + Shared Database)
Localization: LocalizationManager (EnvironmentObject)
```

## 📊 Data Model

7 Core Data entities: **Book**, **Category**, **Transaction**, **Member**, **Budget**, **Account**, **SplitRecord**

Key relationships:
- Book → Categories, Transactions, Members, Budgets, Accounts (1:N, Cascade)
- Transaction → Category, Member (N:1, Nullify)
- Transaction → SplitRecords (1:N, Cascade)

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for:

- Code of Conduct
- How to submit issues and feature requests
- Pull request process and coding standards
- Development workflow

## 📄 Documentation

Full product and technical specification: [LEDGERLY_SPEC.md](./LEDGERLY_SPEC.md)

## 🛡 Security

If you discover a security vulnerability, please do **not** open a public issue. Instead, email the maintainer privately or use [GitHub Security Advisories](https://github.com/DMLayMan/Ledgerly/security/advisories/new).

## 📜 License

Ledgerly is released under the [MIT License](./LICENSE).
