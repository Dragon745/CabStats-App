# 🚖 CabStats

**A comprehensive financial management app for taxi/cab drivers built with Flutter**

CabStats is a powerful, offline-first mobile application designed to help taxi and cab drivers track their rides, manage multiple bank accounts, monitor expenses, and analyze their earnings. With local-first architecture, the app works seamlessly offline and syncs with Firebase when you choose.

![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)
![Flutter](https://img.shields.io/badge/flutter-3.8.1+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## ✨ Features

### 🎯 Core Functionality

- **Ride Management**
  - Start, track, and end rides with GPS location tracking
  - Automatic calculation of metrics (profit, tips, fuel allocation, profit per km/min)
  - Split payments across multiple accounts
  - Comprehensive fee management (toll, platform, airport, parking, etc.)
  - Real-time ride timer and status updates
  - Complete ride history with filtering and search

- **Financial Management**
  - Multi-account balance tracking (up to 4 accounts)
  - Real-time balance updates and transaction history
  - Account transfers with atomic transactions
  - Comprehensive expense tracking with multiple categories
  - Automatic ledger entry creation for all transactions
  - Expense analytics with period filtering (Today, Week, Month, Custom)

- **Fuel & Tips Management**
  - Pending fuel allocation tracking and transfer
  - Refuel recording with kilometer tracking
  - Pending tips accumulation and transfer to savings
  - Fuel allocation automatically calculated from completed rides

- **Local-First Architecture** 🆕
  - Works completely offline - no internet required
  - Fast local storage using Hive database
  - Manual sync with Firebase when you choose
  - Conflict resolution with timestamp-based merging (newest wins)
  - Automatic data migration from Firebase on first launch
  - Network detection and smart sync handling

- **Analytics & Insights**
  - Ride statistics dashboard
  - Expense breakdown by category with visual charts
  - Period-based filtering and navigation
  - Transaction history with detailed categorization
  - Performance metrics (profit per km/min)

### 🎨 User Interface

- **Material Design 3** - Clean, modern Google Material Design
- **Real-time Updates** - Live data streams for balances and rides
- **Intuitive Navigation** - Easy-to-use drawer menu
- **Responsive Design** - Optimized for various screen sizes

## 🛠️ Tech Stack

- **Framework**: Flutter 3.8.1+
- **Language**: Dart
- **Local Database**: Hive 2.2.3 (NoSQL key-value store)
- **Cloud Database**: Firebase Firestore
- **Authentication**: Firebase Auth (Google Sign-In)
- **Location Services**: Geolocator, Geocoding
- **Network Detection**: Connectivity Plus
- **State Management**: StreamBuilder, Hive streams
- **Architecture**: Local-first with manual sync

## 📋 Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Android Studio / Xcode (for mobile development)
- Firebase account and project
- Google Sign-In credentials

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/cabstats.git
   cd cabstats
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters** (required for local storage)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure Firebase**
   - Add your `google-services.json` to `android/app/`
   - Configure Firebase for iOS in Xcode if building for iOS
   - Update Firebase security rules for your Firestore database

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Usage

### First Launch

1. **Sign In**: Launch the app and sign in with your Google account
2. **Account Initialization**: The app automatically sets up your account balances (Main Account, Savings, Fuel Reserve, Emergency Fund)
3. **Data Migration**: If you have existing Firebase data, it will be automatically migrated to local storage on first launch
4. **Ready to Use**: You can now use the app completely offline - no internet required!

### Daily Operations

#### Starting and Managing Rides

1. **Start a Ride**
   - Tap the "Start Ride" button on the home screen
   - The app automatically detects your current location using GPS
   - A ride timer starts tracking the duration
   - Your ride status is shown in real-time

2. **During the Ride**
   - The home screen shows live ride metrics (time, location)
   - You can view your active ride status at any time

3. **Ending a Ride**
   - Tap "End Ride" button when the ride is complete
   - Enter the ride details:
     - **Fare**: Total amount received from customer
     - **Platform Fee**: Commission charged by ride-hailing app (Uber, Ola, etc.)
     - **Toll Fees**: Any toll charges paid
     - **Airport Fees**: Airport charges if applicable
     - **Parking Fees**: Parking charges if any
     - **Other Fees**: Any additional charges
   - **Payment Split**: Choose which account(s) received the payment and split amounts
   - The app automatically calculates:
     - Profit (Fare - Total Fees)
     - Fuel Allocation (percentage of profit for fuel)
     - Profit per KM and per minute
     - Adds pending tip if customer gave a tip

#### Managing Accounts and Balances

1. **Viewing Accounts**
   - Navigate to "Accounts" from the drawer menu
   - View all your account balances in real-time
   - See individual account details and transaction history

2. **Transferring Money**
   - Go to Accounts screen → Tap "Transfer" button
   - Select source and destination accounts
   - Enter the amount
   - Add an optional note
   - **Note**: Transfers are allowed even if source account has insufficient balance (negative balances supported)

3. **Adjusting Account Balance**
   - Use "Adjust" option to manually correct account balances
   - Useful for reconciling with bank statements or correcting errors

#### Recording Expenses

1. **Add an Expense**
   - Navigate to "Expense Stats" from the drawer menu
   - Tap the "+" button to add a new expense
   - Select:
     - **Account**: Which account the expense was paid from
     - **Category**: Type of expense (Fuel, Maintenance, Food, etc.)
     - **Amount**: Expense amount
     - **Description**: Optional description
     - **Date**: Date of expense (defaults to today)
   - **Note**: Expenses can be recorded even if account balance is insufficient (negative balances supported)

2. **View Expense Analytics**
   - View expenses by period (Today, Week, Month, Custom Range)
   - See breakdown by category with visual charts
   - Filter and analyze your spending patterns

#### Fuel Management

1. **Pending Fuel Allocation**
   - Fuel allocation is automatically calculated from completed rides
   - View pending allocation on the Fuel screen
   - **Transfer Fuel Allocation**: Transfer allocated fuel amount to Fuel Reserve account
   - **Adjust Allocation**: Manually adjust the allocation amount if needed
   - **Advance Refueling**: You can transfer fuel or adjust allocation even when there's no pending allocation, allowing advance refueling that creates negative allocations

2. **Recording Refuels**
   - Tap "Refuel" button on Fuel screen
   - Enter:
     - **Kilometer Reading**: Current odometer reading
     - **Amount**: Fuel cost
     - **Location**: Automatically detected or manually entered
   - The refuel is recorded in your ledger and deducted from Fuel Reserve

3. **Refuel History**
   - Tap the history icon to view all past refuels
   - Track fuel expenses and mileage over time

#### Managing Tips

1. **Pending Tips**
   - Tips are automatically accumulated from completed rides
   - View total pending tips on the home screen dashboard
   - Tips accumulate as you complete rides with tips

2. **Transfer Tips to Savings**
   - Use the "Transfer to Savings" option from pending tips card
   - Transfers tips from Main Account to Savings as an expense
   - Helps separate tip income from regular earnings

#### Viewing Analytics and Reports

1. **Ride Statistics**
   - Navigate to "Ride Stats" to see detailed ride analytics
   - View total rides, earnings, profit, and performance metrics
   - Filter by date range
   - See breakdown of payments, fees, and allocations

2. **Expense Analytics**
   - View expense breakdown by category
   - Analyze spending patterns over time
   - Export or view detailed expense reports

3. **Transaction History**
   - View complete ledger of all transactions
   - Filter by account, type, or date range
   - See detailed transaction information

### Advanced Features

#### Negative Balance Support

- **Advance Spending**: You can spend, transfer, or record expenses even when account balance is insufficient
- **Advance Refueling**: Transfer fuel or adjust allocation before rides complete, creating negative allocations that balance out later
- **Financial Flexibility**: Track expenses in advance and manage cash flow better

#### Offline-First Operation

- **No Internet Required**: All operations work completely offline
- **Fast Performance**: Local storage ensures instant operations with no network delays
- **Automatic Sync**: When you sync, all offline changes are synchronized with Firebase

#### Syncing Data

1. **Manual Sync**
   - Open the drawer menu → Tap "Sync Data"
   - The app syncs all local data with Firebase
   - Shows sync progress and status

2. **Conflict Resolution**
   - The app automatically resolves conflicts using timestamp-based logic
   - Latest changes take priority (newest wins)
   - Conflicts are logged and resolved transparently

3. **Sync Status**
   - Check the sync indicator in the app bar
   - Green: Last sync successful
   - Yellow: Sync pending or in progress
   - Red: Sync failed or network issues

### Tips and Best Practices

1. **Daily Workflow**
   - Start ride when customer enters vehicle
   - End ride immediately after drop-off
   - Record expenses as they occur (don't wait)
   - Review transactions periodically

2. **Account Management**
   - Use Fuel Reserve account only for fuel-related transactions
   - Transfer tips to Savings regularly
   - Keep Main Account for daily operations
   - Use Emergency Fund only for unexpected expenses

3. **Fuel Management**
   - Transfer fuel allocation regularly to Fuel Reserve
   - Record refuels immediately after filling up
   - Use advance refueling feature to maintain fuel reserve

4. **Data Backup**
   - Sync with Firebase regularly to backup your data
   - Sync before major app updates
   - Network connectivity not required for daily use

5. **Negative Balances**
   - Use negative balances to track advance spending
   - Negative fuel allocations balance out when rides complete
   - Monitor negative balances to plan cash flow

## 🏗️ Architecture

### Local-First Design

CabStats uses a **local-first architecture** where:

- All data operations happen locally using Hive database
- Firebase sync is manual and optional
- The app works completely offline
- Data migration is automatic on first launch
- Conflict resolution ensures data consistency

### Key Services

- **LocalStorageService**: Handles all local data operations
- **SyncService**: Manages two-way sync between local and Firebase
- **RideService**: Manages ride lifecycle and operations
- **AccountBalanceService**: Handles account balances and transactions
- **NetworkService**: Detects network connectivity
- **MigrationService**: Migrates existing Firebase data to local storage

## 📁 Project Structure

```
lib/
├── models/           # Data models with Hive annotations
├── screens/          # UI screens
│   ├── home_screen.dart
│   ├── accounts_screen.dart
│   ├── rides_history_screen.dart
│   ├── expense_screen.dart
│   └── ...
├── services/         # Business logic services
│   ├── local_storage_service.dart
│   ├── sync_service.dart
│   ├── ride_service.dart
│   └── ...
├── widgets/          # Reusable widgets
└── utils/            # Utility functions
```

## 🔒 Security

- Firebase Authentication for secure user access
- Firestore security rules for data protection
- Local data encrypted by Hive
- No sensitive data stored in plain text

## 🐛 Troubleshooting

### Common Issues

**Issue**: App shows loading spinner on startup
- **Solution**: Ensure Hive is properly initialized. Check that `LocalStorageService.initialize()` was called.

**Issue**: Sync fails or times out
- **Solution**: Check your internet connection. The app includes timeout handling and retry logic for unreliable networks.

**Issue**: Data not syncing properly
- **Solution**: Use manual sync from the drawer menu. Check sync status indicator in the app bar.

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📞 Support

If you encounter any issues or have questions, please open an issue on GitHub.

---

## 👨‍💻 Developer

**Syed Qutubuddin B Asadi**

Passionate developer building innovative solutions. Connect with me through:

<div align="center">

[![Website](https://img.shields.io/badge/Website-syedqutubuddin.in-4285F4?style=for-the-badge&logo=google-chrome&logoColor=white)](https://syedqutubuddin.in)
[![Website14](https://img.shields.io/badge/Website14.com-10B981?style=for-the-badge&logo=globe&logoColor=white)](https://Website14.com)
[![Psychebot](https://img.shields.io/badge/Psychebot.pro-6366F1?style=for-the-badge&logo=robot&logoColor=white)](https://Psychebot.pro)

[![Buy Me A Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/contact9rg)

</div>

---

<div align="center">

**Made with ❤️ by Syed Qutubuddin B Asadi**

⭐ Star this repo if you find it helpful!

</div>
