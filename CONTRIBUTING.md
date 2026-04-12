# Contributing to Ledgerly

First off, thank you for considering contributing to Ledgerly! 🎉

This document provides guidelines and instructions for contributing. By participating, you are expected to uphold our [Code of Conduct](./CODE_OF_CONDUCT.md).

## Table of Contents

- [How Can I Contribute?](#how-can-i-contribute)
  - [Report Bugs](#report-bugs)
  - [Suggest Features](#suggest-features)
  - [Submit Pull Requests](#submit-pull-requests)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Pull Request Process](#pull-request-process)
- [Commit Convention](#commit-convention)
- [Branching Strategy](#branching-strategy)

## How Can I Contribute?

### Report Bugs

Bug reports help us improve Ledgerly. When filing a bug report, please use the **Bug Report** issue template and include:

1. **iOS version and device model** you're running
2. **Steps to reproduce** the issue
3. **Expected behavior** vs **actual behavior**
4. **Screenshots or screen recordings** if applicable
5. Any relevant console output or crash logs

### Suggest Features

Feature suggestions are welcome! Please use the **Feature Request** issue template and include:

1. **Problem statement** — What problem does this feature solve?
2. **Proposed solution** — How would you like it to work?
3. **Alternatives considered** — Any alternative approaches you've thought of
4. **Additional context** — Screenshots, mockups, or references to other apps

### Submit Pull Requests

We actively welcome pull requests. See [Pull Request Process](#pull-request-process) below for details.

## Development Setup

### Prerequisites

- **Xcode 16.0+**
- **XcodeGen** — Install via Homebrew: `brew install xcodegen`
- **Git LFS** (optional, for large assets)

### Quick Start

```bash
# 1. Fork and clone
git clone https://github.com/<your-username>/Ledgerly.git
cd Ledgerly

# 2. Create a feature branch
git checkout -b feature/your-feature-name

# 3. Generate Xcode project
xcodegen generate

# 4. Open in Xcode
open Ledgerly.xcodeproj

# 5. Build and run on simulator
./run_device.sh --simulator
```

### iCloud Setup (Optional)

If your changes involve CloudKit or shared ledger functionality:

1. Set your **Development Team** in Xcode project settings
2. Update the iCloud container identifier in `Ledgerly/Ledgerly.entitlements` and `project.yml`
3. Create the CloudKit container in the [CloudKit Console](https://icloud.developer.apple.com/)

## Coding Standards

### Swift Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use **SwiftUI** for all UI components — no UIKit unless absolutely necessary
- Target **Swift 5.9** with no compiler warnings
- Use `async/await` and `@MainActor` for concurrency

### Architecture

- Follow the **MVVM** pattern established in the project
- Views should be thin — business logic belongs in ViewModels
- Use `@EnvironmentObject` for shared state (e.g., `LocalizationManager`)
- Core Data operations go through `PersistenceController.shared`

### Localization

- All user-facing strings must use `LocalizationManager` with a localization key
- Add new keys to both `en` and `zhHans` dictionaries in `LocalizationManager.swift`
- Use `LocalizationManager.localized(_:)` for non-View contexts (ViewModels, Services)
- Use `loc["key"]` syntax in Views (via `@EnvironmentObject var loc: LocalizationManager`)

### Naming Conventions

- **Files**: PascalCase matching the primary type (e.g., `CategoryViewModel.swift`)
- **Types**: PascalCase (e.g., `TransactionType`)
- **Functions/properties**: camelCase
- **Localization keys**: camelCase, grouped by feature (e.g., `settingsLanguage`, `billSearchPlaceholder`)

### Core Data

- Never modify `.xcdatamodel` directly without updating corresponding `+CoreData.swift` extensions
- Use lightweight migrations for schema changes — add new fields as **optional** with a default value
- Always test migration from the previous schema version

## Pull Request Process

1. **Create an issue first** — Discuss the change before investing significant effort (except for trivial fixes)
2. **Fork and branch** — Create a branch from `main` following the [branching strategy](#branching-strategy)
3. **Make your changes** — Follow coding standards above
4. **Test thoroughly** — Run the app on simulator and verify your changes don't break existing functionality
5. **Update documentation** — If your change affects the public API or user-facing behavior, update [LEDGERLY_SPEC.md](./LEDGERLY_SPEC.md)
6. **Commit with clear messages** — Follow [commit convention](#commit-convention)
7. **Open a PR** — Use the **Pull Request** template, link the related issue, and fill in all sections
8. **Code review** — At least one maintainer review is required before merge
9. **CI checks** — All automated checks must pass

### PR Checklist

- [ ] Code compiles without warnings
- [ ] New user-facing strings are localized (both EN and ZH)
- [ ] Core Data changes include lightweight migration support
- [ ] No third-party dependencies added (without prior discussion)
- [ ] Documentation updated if needed

## Commit Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `style` | Code style changes (formatting, no logic change) |
| `refactor` | Code refactoring (no feature or fix) |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `chore` | Build, tooling, or CI changes |
| `i18n` | Localization changes |

### Examples

```
feat(record): add expression parser for quick entry
fix(sync): resolve CloudKit merge conflict on shared ledgers
docs(readme): add installation instructions for real devices
i18n(settings): add Japanese language support
chore(deps): update XcodeGen to 2.42
```

## Branching Strategy

| Branch | Purpose | Naming |
|--------|---------|--------|
| `main` | Stable release branch | — |
| `feature/*` | New features | `feature/add-recurring-transactions` |
| `fix/*` | Bug fixes | `fix/bill-list-crash` |
| `refactor/*` | Code refactoring | `refactor/simplify-viewmodels` |
| `docs/*` | Documentation | `docs/update-api-reference` |
| `release/*` | Release preparation | `release/1.1.0` |

### Rules

- All changes must go through a pull request — **no direct pushes to `main`**
- Keep branches focused — one feature/fix per branch
- Rebase your branch on `main` before opening a PR to minimize merge conflicts
- Delete your branch after the PR is merged

---

Thank you for contributing to Ledgerly! 💰
