# 🚖 CabStats

**A comprehensive financial management app for taxi/cab drivers built with Flutter**

CabStats is a powerful, offline-first mobile application designed to help taxi and cab drivers track their rides, manage multiple bank accounts, monitor expenses, and analyze their earnings. With local-first architecture, the app works seamlessly offline and syncs with Firebase when you choose.

![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)
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

1. Sign in with your Google account
2. The app automatically initializes account balances
3. If you have existing Firebase data, it will be migrated to local storage automatically
4. You can now use the app completely offline

### Daily Operations

- **Start a Ride**: Tap "Start Ride" on the home screen. The app will detect your location automatically.
- **End a Ride**: Use the "End Ride" button to complete a ride and enter fare, fees, and payment details.
- **Track Expenses**: Navigate to "Expense Stats" from the drawer to add and view expenses.
- **Manage Accounts**: Use the "Accounts" screen to view balances and transfer funds between accounts.
- **Fuel Management**: Access the "Fuel" screen to track fuel allocations and refuels.

### Syncing Data

- **Manual Sync**: Use the "Sync Data" option from the drawer menu to sync with Firebase
- **Conflict Resolution**: The app automatically resolves conflicts using timestamp-based logic (newest wins)
- **Sync Status**: Check the sync indicator in the app bar to see sync status

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
