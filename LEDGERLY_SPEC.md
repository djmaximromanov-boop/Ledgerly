# Ledgerly — 完整产品与技术文档

> 本文档旨在提供完整的产品方案与技术实现细节，使 AI 或开发者能够基于此文档从零重建该 APP。

---

## 一、产品概述

### 1.1 产品定位

**Ledgerly** 是一款开源的 iOS 原生记账应用，支持个人记账与家庭/团队共享记账场景。核心价值是「快速记录、清晰统计、多人协作」。项目无国家/地区限制，全球用户均可使用。

**Slogan：Your money. Your data. Your rules.**

### 1.2 目标用户

- 个人用户：日常收支记录、预算管理
- 家庭用户：家庭共同记账、成员支出对比
- 团队用户：团队经费管理、AA 分摊

### 1.3 平台与版本

| 项目 | 值 |
|---|---|
| 平台 | iOS 17.0+ |
| 语言 | Swift 5.9 |
| 框架 | SwiftUI + SwiftData(Core Data) + CloudKit + Charts |
| 构建工具 | Xcode 16.0 + XcodeGen (project.yml) |
| Bundle ID | com.ledgerly.app |
| iCloud 容器 | iCloud.com.ledgerly.app |
| 版本 | 1.0.0 |
| 设备 | iPhone only（TARGETED_DEVICE_FAMILY: 1） |
| 方向 | 仅竖屏 |

---

## 二、功能清单

### 2.1 核心功能

| 功能模块 | 功能点 | 描述 |
|---|---|---|
| **快速记账** | 金额输入 | 自定义数字键盘，支持四则运算（+、-、×），自动求值（=） |
| | 支出/收入切换 | 顶部切换按钮，切换后分类列表联动刷新 |
| | 分类选择 | 两级分类网格，一级→二级联动 |
| | 日期选择 | 默认今天，可通过菜单选择其他日期 |
| | 备注输入 | 可选，通过菜单进入备注页面 |
| | 保存确认 | 保存后显示 Toast 提示 + 触觉反馈 |
| **账单列表** | 月度筛选 | 左右切换月份，带滑动动画 |
| | 搜索 | 按备注/分类名搜索交易记录 |
| | 汇总卡片 | 当月支出/收入/结余三栏汇总 |
| | 按日分组 | 交易按天分组，每行显示日支出小计 |
| | 滑动删除 | 左滑删除交易，带缩放动画 |
| **统计分析** | 时段选择 | 周/月/年三档，前后导航 |
| | 收支趋势图 | 折线+面积图，支出红色、收入绿色、结余蓝色柱状 |
| | 分类饼图 | 支出按一级分类占比，环形图 + 图例 |
| | 分类详情 | 点击分类查看二级分类柱状图 + 交易明细 |
| | 成员对比 | 共享账本专属，柱状图对比各成员支出 |
| **账本管理** | 创建账本 | 个人/共享两种类型，选择图标 |
| | 切换账本 | 全局切换当前活跃账本 |
| | 删除账本 | 滑动删除 |
| **预算管理** | 添加预算 | 月度/年度，输入金额 |
| | 进度条 | 渐变色进度条（绿→黄→红），超支警告 |
| | 超支提醒 | 预算超支时发送本地通知 |
| **分类管理** | 预设分类 | 10 大支出分类 + 4 大收入分类，含二级子分类 |
| | 自定义分类 | 添加/编辑/删除自定义分类 |
| | 分类排序 | 拖拽排序 |
| | 图标选择 | 70+ SF Symbols 图标库 |
| **共享记账** | 成员管理 | 添加/删除成员，设置角色（owner/editor/viewer） |
| | iCloud 共享 | 通过 CloudKit CKShare 共享账本 |
| | AA 分摊 | 平均分摊或自定义比例分摊 |
| **数据管理** | iCloud 同步 | NSPersistentCloudKitContainer 自动同步 |
| | 数据导出 | CSV / JSON 格式导出 |
| | 数据归档 | 6 个月以上旧数据自动归档至 CloudKit |
| **设置** | 货币选择 | CNY/USD/EUR/JPY |
| | 每日提醒 | 22:00 本地通知提醒记账 |

### 2.2 用户流程

```
首次启动 → 自动创建演示数据（个人账本 + 家庭账本 + 90天模拟交易）
    │
    ├─ 记账流程：选择账本 → 选择支出/收入 → 选择分类 → 输入金额 → 保存
    │
    ├─ 查看账单：切换月份 → 查看汇总 → 搜索/浏览 → 删除
    │
    ├─ 统计分析：选择时段 → 查看趋势 → 点击分类 → 查看明细
    │
    ├─ 管理账本：创建/切换/删除 → 管理预算 → 管理成员
    │
    └─ 设置：货币/导出/通知
```

---

## 三、技术架构

### 3.1 整体架构

```
LedgerlyApp (入口)
  └─ ContentView (TabView, 5 个 Tab)
       ├─ QuickEntryView      (记账)
       ├─ BillListView        (账单)
       ├─ StatisticsView      (统计)
       ├─ BookManagementView  (账本)
       └─ SettingsView        (设置)

架构模式：MVVM (Model-View-ViewModel)
数据持久化：Core Data + NSPersistentCloudKitContainer
云同步：CloudKit (Private Database + Shared Database)
图表：SwiftUI Charts (iOS 16+)
```

### 3.2 目录结构

```
Ledgerly/
├── LedgerlyApp.swift               # App 入口
├── ContentView.swift                # TabView 主容器
├── Info.plist                       # 应用配置
├── Ledgerly.entitlements            # iCloud 权限
├── Models/
│   ├── CoreData/
│   │   ├── Ledgerly.xcdatamodeld/ # Core Data 模型定义
│   │   ├── Book+CoreData.swift      # 账本实体
│   │   ├── Account+CoreData.swift   # 账户实体
│   │   ├── Transaction+CoreData.swift # 交易实体
│   │   ├── Category+CoreData.swift  # 分类实体（含预设分类数据）
│   │   ├── Budget+CoreData.swift    # 预算实体
│   │   ├── Member+CoreData.swift    # 成员实体
│   │   └── SplitRecord+CoreData.swift # 分摊记录实体
│   └── Enums/
│       ├── BookType.swift           # personal / shared
│       ├── TransactionType.swift    # expense / income
│       ├── CategoryType.swift       # expense / income
│       ├── AccountType.swift        # cash / bank / credit
│       ├── BudgetPeriod.swift       # monthly / yearly
│       └── MemberRole.swift         # owner / editor / viewer
├── Persistence/
│   ├── PersistenceController.swift  # Core Data 栈 + 种子数据
│   └── CoreDataStack.swift          # 通用查询封装
├── ViewModels/
│   ├── BookViewModel.swift          # 账本 CRUD + 当前账本切换
│   ├── TransactionViewModel.swift   # 交易保存/删除 + 分类查询
│   ├── CategoryViewModel.swift      # 分类 CRUD
│   ├── BudgetViewModel.swift        # 预算 CRUD + 进度计算
│   └── StatisticsViewModel.swift    # 统计数据聚合 + 趋势计算
├── Views/
│   ├── Tabs/
│   │   ├── QuickEntryView.swift     # 记账页
│   │   ├── BillListView.swift       # 账单页
│   │   ├── StatisticsView.swift      # 统计页
│   │   ├── BookManagementView.swift  # 账本管理页
│   │   ├── CategoryListView.swift    # 分类管理页
│   │   └── SettingsView.swift        # 设置页
│   ├── Components/
│   │   ├── AmountKeyboard.swift      # 自定义数字键盘
│   │   ├── GridCategoryView.swift    # 分类网格选择器
│   │   ├── BookHeaderView.swift      # 账本信息头部
│   │   ├── MonthPicker.swift         # 月份选择器
│   │   ├── TransactionRow.swift      # 交易行视图
│   │   ├── QuickAddCategoryView.swift # 快速添加分类
│   │   └── BudgetProgressView.swift  # 预算进度条
│   ├── Charts/
│   │   ├── CategoryPieChart.swift    # 分类饼图
│   │   ├── TrendChartView.swift      # 趋势折线图
│   │   └── MemberComparisonChart.swift # 成员对比柱状图
│   └── Sharing/
│       ├── ShareBookView.swift       # iCloud 共享
│       ├── MemberListView.swift      # 成员管理
│       ├── SplitSetupView.swift      # AA 分摊设置
│       └── CategorySortView.swift    # 分类排序
├── Services/
│   ├── CloudKitService.swift         # CloudKit 操作封装
│   ├── SharingService.swift          # 共享逻辑 + ServiceLocator
│   ├── NotificationService.swift     # 本地通知
│   └── ArchiveService.swift          # 数据归档
├── Extensions/
│   ├── Color+Theme.swift             # 主题颜色 + 渐变
│   ├── Date+Helpers.swift            # 日期工具
│   └── Decimal+Formatting.swift      # 货币格式化
└── Resources/
    └── Assets.xcassets/              # 资源文件
```

### 3.3 依赖关系

```
无第三方依赖。全部使用 Apple 原生框架：
- SwiftUI          : UI 层
- Core Data        : 本地持久化
- CloudKit         : 云同步与共享
- Charts           : 统计图表 (iOS 16+)
- UserNotifications: 本地通知
- Foundation       : 基础工具
```

---

## 四、数据模型

### 4.1 实体关系图 (ER Diagram)

```
Book (1) ──────< (N) Category
Book (1) ──────< (N) Transaction
Book (1) ──────< (N) Member
Book (1) ──────< (N) Budget
Book (1) ──────< (N) Account

Category (1) ──< (N) Transaction    (通过 parentId 实现二级分类)
Member (1) ────< (N) Transaction
Member (1) ────< (N) SplitRecord
Transaction (1) ─< (N) SplitRecord
```

### 4.2 实体详细定义

#### Book（账本）

| 字段 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| id | UUID | - | 主键 |
| name | String | - | 账本名称 |
| icon | String | "book" | SF Symbol 图标名 |
| type | String | "personal" | 枚举 BookType: personal/shared |
| currency | String | "CNY" | 货币代码 |
| createdAt | Date | - | 创建时间 |

关系：categories(1:N Cascade), members(1:N Cascade), transactions(1:N Cascade), budgets(1:N Cascade), accounts(1:N Cascade)

计算属性：totalExpense, totalIncome, balance

#### Transaction（交易）

| 字段 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| id | UUID | - | 主键 |
| amount | Decimal | 0.0 | 金额 |
| type | String | "expense" | 枚举 TransactionType: expense/income |
| date | Date | - | 交易日期 |
| note | String? | nil | 备注 |
| tagsData | Binary? | nil | JSON 编码的标签数组 |
| createdAt | Date | - | 创建时间 |
| updatedAt | Date | - | 更新时间 |

关系：book(N:1), category(N:1), member(N:1), splitRecords(1:N Cascade)

计算属性：transactionType, tagsList, formattedAmount

#### Category（分类）

| 字段 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| id | UUID | - | 主键 |
| name | String | - | 分类名称 |
| icon | String | "folder" | SF Symbol 图标名 |
| type | String | "expense" | 枚举 CategoryType: expense/income |
| parentId | UUID? | nil | 父分类 ID（二级分类指向一级） |
| sortOrder | Int32 | 0 | 排序权重 |
| isSystem | Bool | false | 是否系统预设分类 |

关系：book(N:1), transactions(1:N Nullify)

计算属性：isTopLevel, canDelete

#### Member（成员）

| 字段 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| id | UUID | - | 主键 |
| name | String | - | 成员名称 |
| role | String | "editor" | 枚举 MemberRole: owner/editor/viewer |
| userId | String? | nil | iCloud 用户 ID |
| joinedAt | Date | - | 加入时间 |

关系：book(N:1), transactions(1:N Nullify), splitRecords(1:N Nullify)

#### Budget（预算）

| 字段 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| id | UUID | - | 主键 |
| amount | Decimal | 0.0 | 预算金额 |
| period | String | "monthly" | 枚举 BudgetPeriod: monthly/yearly |
| categoryId | UUID? | nil | 关联分类 ID（nil 表示总预算） |
| startDate | Date | - | 起始日期 |

关系：book(N:1)

#### Account（账户）

| 字段 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| id | UUID | - | 主键 |
| name | String | - | 账户名称 |
| type | String | "cash" | 枚举 AccountType: cash/bank/credit |
| balance | Decimal | 0.0 | 余额 |
| icon | String | "wallet" | SF Symbol 图标名 |

关系：book(N:1)

#### SplitRecord（分摊记录）

| 字段 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| id | UUID | - | 主键 |
| shareAmount | Decimal | 0.0 | 分摊金额 |
| shareRatio | Double | 0.0 | 分摊比例 |

关系：member(N:1), transaction(N:1)

### 4.3 枚举定义

```swift
enum BookType: String { case personal, shared }
enum TransactionType: String { case expense, income }
enum CategoryType: String { case expense, income }
enum AccountType: String { case cash, bank, credit }
enum BudgetPeriod: String { case monthly, yearly }
enum MemberRole: String { case owner, editor, viewer }
```

### 4.4 预设分类数据

**支出分类（10 大类）：**

| 一级分类 | 图标 | 二级子分类 |
|---|---|---|
| 餐饮 | fork.knife | 早餐、午餐、晚餐、零食、饮料、水果、外卖 |
| 交通 | car.fill | 公交、地铁、打车、加油、停车、过路费、共享单车 |
| 购物 | bag.fill | 衣服、日用品、数码、化妆品、鞋包、家电 |
| 住房 | house.fill | 房租、水电、物业、维修、燃气、网费 |
| 娱乐 | gamecontroller.fill | 电影、游戏、旅行、运动、音乐、聚会 |
| 医疗 | stethoscope | 门诊、药品、体检、牙科、保健 |
| 教育 | book.fill | 培训、书籍、课程、考试、文具 |
| 通讯 | phone.fill | 话费、网络、会员、快递 |
| 人情 | gift.fill | 红包、礼金、请客、礼物 |
| 宠物 | pawprint.fill | 猫粮、狗粮、宠物医疗、宠物用品 |

**收入分类（4 大类）：**

| 一级分类 | 图标 | 二级子分类 |
|---|---|---|
| 工资 | banknote.fill | 月薪、奖金、加班、年终奖 |
| 投资 | chart.line.uptrend.xyaxis | 股票、基金、利息、理财 |
| 兼职 | briefcase.fill | 外包、咨询、稿费 |
| 其他收入 | plus.circle.fill | 红包、退款、报销、中奖 |

---

## 五、ViewModel 逻辑

### 5.1 BookViewModel

- **职责**：管理账本列表、当前账本切换、创建/删除账本
- **关键属性**：books, currentBook, showCreateSheet, newBookName/Icon/Type
- **关键方法**：
  - `fetchBooks()`: 按 createdAt 排序获取所有账本
  - `createBook()`: 创建账本 + 默认分类 + 默认 owner 成员
  - `deleteBook(_:)`: 删除账本并切换到下一个
  - `switchBook(to:)`: 切换当前活跃账本
- **通知监听**：NSManagedObjectContextDidSave → 自动刷新列表

### 5.2 TransactionViewModel

- **职责**：管理交易表单状态、保存/删除交易
- **关键属性**：amountText, selectedType, selectedCategory, note, tags, date, currentBook
- **计算属性**：amount (Decimal), canSave (amount > 0 && category != nil && book != nil)
- **关键方法**：
  - `saveTransaction()`: 创建 Transaction 并保存到 Core Data
  - `deleteTransaction(_:)`: 删除交易
  - `expenseCategories(for:)` / `incomeCategories(for:)`: 获取顶层分类
  - `subCategories(of:)`: 获取二级分类

### 5.3 CategoryViewModel

- **职责**：分类的增删改查
- **关键方法**：
  - `addCategory(...)`: 校验名称非空，自动计算 sortOrder
  - `updateCategory(...)`: 修改名称和图标
  - `deleteCategory(_:)`: 系统分类不可删，有关联交易不可删
  - `getCategories(for:type:)` / `getSubCategories(for:)`: 查询

### 5.4 BudgetViewModel

- **职责**：预算管理 + 进度计算
- **关键方法**：
  - `spentAmount(for:in:)`: 按预算周期（月/年）和分类过滤计算已支出金额
  - `progress(for:in:)`: 返回 0~1 的进度值
  - `isOverBudget(_:in:)`: 判断是否超支
  - `createBudget(for:amount:period:categoryId:)`: 创建预算

### 5.5 StatisticsViewModel

- **职责**：统计聚合计算
- **时段**：week / month / year
- **关键计算**：
  - `totalExpense` / `totalIncome` / `totalBalance`: 总计
  - `expenseByCategory`: 按一级分类聚合支出，子分类归入父分类
  - `expenseBySubCategory(parent:)`: 指定分类的二级明细
  - `expenseByMember`: 按成员聚合支出
  - `trendData`: 日/月趋势数据点（TrendDataPoint: date, label, expense, income, balance）
  - `dailyTrendData`: 周/月视图按日聚合
  - `monthlyTrendData`: 年视图按月聚合

---

## 六、视图层详解

### 6.1 Tab 结构

| Tab | 标题 | 图标 | 视图 |
|---|---|---|---|
| 0 | 记账 | plus.circle | QuickEntryView |
| 1 | 账单 | list.bullet | BillListView |
| 2 | 统计 | chart.pie | StatisticsView |
| 3 | 账本 | book | BookManagementView |
| 4 | 设置 | gearshape | SettingsView |

### 6.2 QuickEntryView（记账页）

布局从上到下：
1. **金额卡片**：渐变背景（支出红/收入绿），包含账本切换菜单、支出/收入切换、金额显示、已选分类标签、日期/备注 chip
2. **分类网格**：GridCategoryView，一级分类 → 二级分类联动选择
3. **自定义键盘**：AmountKeyboard，4×4 布局 + 保存按钮

交互细节：
- 切换支出/收入时，分类列表和主题色动画切换
- 保存成功后 Toast 提示 + UIImpactFeedbackGenerator 触觉反馈
- 金额支持四则运算表达式，保存时自动求值

### 6.3 BillListView（账单页）

布局：
1. BookHeaderView（账本信息 + 成员头像）
2. MonthPicker（月份切换）
3. 汇总卡片（支出/收入/结余三栏渐变背景）
4. 交易列表（按日分组，日支出小计）

交互：
- 搜索栏：覆盖在顶部，支持按备注/分类名搜索
- 左滑删除：带缩放动画
- 月份切换：内容淡入淡出过渡

### 6.4 StatisticsView（统计页）

布局：
1. BookHeaderView
2. 时段选择器（周/月/年 segmented + 前后导航）
3. 汇总卡片（SummaryCard × 3）
4. 收支趋势图（LineMark + AreaMark + BarMark）
5. 分类饼图（SectorMark + 图例列表）
6. 成员对比（共享账本专属，BarMark）

交互：
- 点击分类图例 → sheet 弹出 CategoryDetailView（二级分类柱状图 + 交易明细）

### 6.5 BookManagementView（账本管理页）

布局：
1. 个人账本 Section（点击切换，滑动删除）
2. 共享账本 Section（点击切换，滑动进入成员管理）
3. 预算管理 Section（BudgetProgressView + 添加预算）

创建账本：Sheet 弹出 CreateBookView，包含名称输入、类型选择（个人/共享卡片）、图标网格

### 6.6 SettingsView（设置页）

Section 结构：
1. 通用：货币选择
2. 数据：分类管理、导出数据（CSV/JSON）、数据管理（iCloud 同步说明）
3. 关于：版本号、隐私政策链接

### 6.7 CategoryListView（分类管理页）

布局：
1. 类型切换（支出/收入 segmented）
2. 统计栏（一级/二级/总计数量）
3. 分类列表（图标 + 名称 + 系统标签 + 操作菜单）

Sheet：分类编辑（名称输入 + 图标网格选择）

---

## 七、核心组件

### 7.1 AmountKeyboard（自定义数字键盘）

```
布局：
  [1] [2] [3] [+]
  [4] [5] [6] [-]
  [7] [8] [9] [×]
  [.] [0] [⌫] [=]
  [    保存    ]
```

逻辑：
- 数字输入：最多 12 位，小数点后最多 2 位
- 运算符：+、-、×，不可连续输入，自动替换上一个运算符
- `=` 键：使用 NSExpression 求值
- 保存时：如果包含运算符，先求值再回调 onConfirm

### 7.2 GridCategoryView（分类网格选择器）

- 水平分页滚动，每页 4 列 × 2 行 = 8 个分类
- 一级分类选中后展开二级分类区域
- 二级分类为空时，一级分类直接作为选中项
- 每页末尾有虚线框「添加」按钮
- 选中动画：弹跳缩放效果

### 7.3 MonthPicker（月份选择器）

- 左右箭头切换月份，带滑动方向动画
- 当前月份高亮为主题色
- 按压缩放反馈

### 7.4 BudgetProgressView（预算进度条）

- 进度 < 50%：绿色渐变
- 进度 50%~80%：绿→黄渐变
- 进度 80%~100%：黄→红渐变
- 超支：红色 + 警告图标 + 超支金额提示

---

## 八、服务层

### 8.1 PersistenceController

- 使用 `NSPersistentCloudKitContainer(name: "Ledgerly")`
- 启用 `NSPersistentHistoryTrackingKey` 和 `NSPersistentStoreRemoteChangeNotificationPostOptionKey`
- 模拟器环境禁用 CloudKit（`cloudKitContainerOptions = nil`）
- `automaticallyMergesChangesFromParent = true`
- `mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy`
- `seedDemoDataIfNeeded()`: 首次启动创建 2 个账本 + 90 天模拟数据

### 8.2 CloudKitService (actor)

- 容器：`iCloud.com.ledgerly.app`
- 每个共享账本一个 Custom Zone：`BookZone_{bookId}`
- 关键方法：
  - `createSharedBookZone(bookId:)`: 创建自定义 Zone
  - `createBookRecord(book:in:)`: 保存账本记录到 CloudKit
  - `createShare(for:in:)`: 创建 CKShare
  - `saveTransaction(_:bookId:)`: 保存交易到 CloudKit
  - `deleteTransaction(_:bookId:)`: 从 CloudKit 删除交易
  - `fetchSharedZones()`: 获取所有共享 Zone
  - `acceptShare(metadata:)`: 接受共享邀请
  - `fetchSharedDatabaseRecords()`: 从 Shared Database 获取记录

### 8.3 SharingViewModel + ServiceLocator

- `SharingViewModel`: 管理共享状态，创建共享账本流程
- `ServiceLocator`: 单例服务定位器，持有 PersistenceController 弱引用

### 8.4 NotificationService

- `requestAuthorization()`: 请求通知权限
- `scheduleBudgetOverrunNotification(...)`: 预算超支即时通知
- `scheduleDailyReminder()`: 每天 22:00 记账提醒
- `cancelDailyReminder()`: 取消每日提醒

### 8.5 ArchiveService (actor)

- 归档阈值：6 个月 或 10,000 条记录
- 流程：查询旧记录 → 复制到 ArchiveZone → 删除原记录 → 创建 MonthlySummary
- 分页处理：使用 CKQueryOperation.Cursor 逐批处理

---

## 九、主题与样式

### 9.1 颜色系统

```swift
// 主题色
expenseColor = Color(red: 0.91, green: 0.30, blue: 0.24)  // 红色
incomeColor  = Color(red: 0.20, green: 0.78, blue: 0.55)  // 绿色

// 渐变
expenseGradient: 红→橙渐变 (topLeading → bottomTrailing)
incomeGradient:  深绿→浅绿渐变
balanceGradient: 蓝色渐变

// 分类颜色轮
categoryColor(for:): 12 色循环 [orange, blue, purple, pink, teal, indigo, mint, cyan, brown, yellow, red, green]

// Asset 颜色
AppPrimary, AppSecondary, AppBackground, AppCard, AppText, AppTextSecondary, AppExpense, AppIncome
```

### 9.2 金额格式化

```swift
Decimal.currencyString   // 货币格式化字符串，如 "¥1,234.56" / "$1,234.56"（跟随 currencyCode 设置）
Decimal.compactString    // 紧凑格式，如 "1.2万" / "1.5K" / "1.0M"
Decimal.percentageString // 百分比格式，如 "85.5%"
```

### 9.3 日期工具

```swift
Date.startOfDay / .endOfDay
Date.startOfMonth / .endOfMonth
Date.startOfYear / .endOfYear
Date.monthString     // 月份字符串，如 "2024年1月"（跟随系统 locale 格式化）
Date.shortDateString // 短日期字符串，如 "1月15日"（跟随系统 locale 格式化）
Date.isToday / .isThisMonth
Date.adding(months:) / .adding(days:)
```

---

## 十、数据流

### 10.1 环境注入

```
LedgerlyApp
  └─ ContentView
       .environment(\.managedObjectContext, PersistenceController.shared.viewContext)
       .environmentObject(bookVM)  // BookViewModel
```

所有子视图通过 `@EnvironmentObject var bookVM: BookViewModel` 和 `@Environment(\.managedObjectContext)` 获取数据上下文。

### 10.2 数据流向

```
View → ViewModel → PersistenceController → Core Data → CloudKit (自动同步)
                                              ↓
                                    NSFetchedResultsController / @FetchRequest
                                              ↓
                                           View 更新
```

### 10.3 状态管理

- **全局状态**：BookViewModel（通过 EnvironmentObject 注入）
- **页面状态**：各 ViewModel 通过 @StateObject 在页面创建
- **持久化状态**：@AppStorage（货币、默认账本 ID）
- **Core Data 变更通知**：NSManagedObjectContextDidSave → BookViewModel.fetchBooks()

---

## 十一、Core Data 模型 XML

完整的 `.xcdatamodeld` 定义见 `Ledgerly/Models/CoreData/Ledgerly.xcdatamodeld/Ledgerly.xcdatamodel/contents`。

7 个实体：Book, Category, Transaction, Member, Budget, Account, SplitRecord

关键删除规则：
- Book → categories/members/transactions/budgets/accounts: **Cascade**（删除账本时级联删除）
- Category/Member → transactions: **Nullify**（删除分类/成员时，交易保留但外键置空）
- Transaction → splitRecords: **Cascade**

---

## 十二、构建配置

### 12.1 XcodeGen (project.yml)

项目使用 XcodeGen 生成 `.xcodeproj`，配置文件为 `project.yml`：

```yaml
name: Ledgerly
options:
  bundleIdPrefix: com.ledgerly
  deploymentTarget:
    iOS: "17.0"
  xcodeVersion: "16.0"
settings:
  base:
    SWIFT_VERSION: "5.9"
    TARGETED_DEVICE_FAMILY: "1"
```

### 12.2 Entitlements

- `com.apple.developer.icloud-container-identifiers`: `iCloud.com.bookkeeper.app`
- `com.apple.developer.ubiquity-container-identifiers`: `iCloud.com.bookkeeper.app`
- `com.apple.developer.icloud-container-environment`: Production

### 12.3 Info.plist 关键配置

- `CFBundleDisplayName`: Ledgerly
- `CFBundleDevelopmentRegion`: zh_CN
- `CKSharingSupported`: true
- `NSCloudKitUsageDescription`: Ledgerly needs iCloud to sync your data and support shared ledgers with family members
- `UIBackgroundModes`: remote-notification
- `UISupportedInterfaceOrientations`: UIInterfaceOrientationPortrait

---

## 十三、重建指南

### 13.1 项目创建步骤

1. **创建 Xcode 项目**：iOS App, SwiftUI, Core Data + CloudKit
2. **配置 project.yml**：按上述配置编写，运行 `xcodegen generate`
3. **创建 Core Data 模型**：按第四章实体定义创建 7 个实体
4. **创建枚举文件**：6 个枚举文件
5. **创建 Core Data 扩展**：7 个 `+CoreData.swift` 文件，含计算属性和工厂方法
6. **创建 Persistence 层**：PersistenceController + CoreDataStack
7. **创建 Extensions**：Color+Theme, Date+Helpers, Decimal+Formatting
8. **创建 Services**：4 个服务文件
9. **创建 ViewModels**：5 个 ViewModel
10. **创建 Views**：按目录结构创建所有视图
11. **配置 Entitlements**：iCloud 容器
12. **配置 Info.plist**：按上述配置

### 13.2 关键注意事项

1. **Core Data 模型名称**必须为 `Ledgerly`，与 `NSPersistentCloudKitContainer(name: "Ledgerly")` 一致
2. **CloudKit 容器 ID**必须为 `iCloud.com.ledgerly.app`，且需在 Apple Developer 后台配置
3. **模拟器环境**自动禁用 CloudKit 同步（通过 `#if targetEnvironment(simulator)` 判断）
4. **首次启动**自动调用 `seedDemoDataIfNeeded()` 生成演示数据
5. **Category 的预设数据**在 `Category+CoreData.swift` 的静态属性中定义
6. **所有 ViewModel** 标记 `@MainActor`
7. **CloudKitService 和 ArchiveService** 使用 `actor` 确保线程安全
8. **金额使用 Decimal/NSDecimalNumber**，避免浮点精度问题

### 13.3 最小可运行版本

如需最小化重建，核心路径为：

1. LedgerlyApp + ContentView（TabView 骨架）
2. Core Data 模型（Book + Transaction + Category 三个核心实体）
3. PersistenceController（含 seedDemoData）
4. BookViewModel + TransactionViewModel
5. QuickEntryView + BillListView（记账 + 查看两个核心页面）
6. AmountKeyboard + GridCategoryView + TransactionRow（核心组件）
7. Color+Theme + Date+Helpers + Decimal+Formatting（工具扩展）

其余功能（统计、预算、共享、归档等）可逐步添加。
