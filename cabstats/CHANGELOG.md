# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-10-26

### Added

- **HomeScreen Dashboard Google Material Design Redesign**: Complete UI overhaul following Material Design 3 principles

  - **Google Material Design 3 UI**: Redesigned home dashboard to match Google's design language
    - Clean, minimal cards with flat design and subtle borders (`#E8EAED`)
    - White AppBar with surface tint and Material typography
    - Light grey background (`#F8F9FA`)
    - Ride cards with solid color backgrounds (blue `#4285F4`, green `#10B981`, orange `#FB8500`)
    - Icon containers with rounded corners and transparency overlays
    - Material FilledButtons and OutlinedButtons with 24px border radius
    - Consistent 12px border radius throughout
    - Zero elevation, flat Material design
    - Refined typography with proper letter spacing (0, -0.5, -1)
    - Clean spacing (16px, 12px, 8px)
  - **Account Balance Card**: Material Design 3 styling
    - White card with light grey border
    - 36px balance text with weight 400
    - IconButtons with light grey backgrounds
    - Account breakdown with colored icon containers (8% opacity)
    - Blue balance text (`#4285F4`)

- **Accounts Screen Google Material Design Redesign**: Complete UI overhaul following Material Design 3 principles

  - **Google Material Design 3 UI**: Redesigned accounts screen to match Google's design language
    - Clean, minimal cards with flat design and subtle borders (`#E8EAED`)
    - White FilledButtons with blue text for primary actions
    - Total balance card with blue background (`#4285F4`) and refined typography
    - Account cards with icon containers using 8% opacity backgrounds
    - Consistent 12px border radius throughout
    - Zero elevation, flat Material design
    - Refined typography with proper letter spacing
    - Clean spacing and padding (16px, 8px spacing)
  - **Menu Drawer Redesign**: Google Material Design 3 styling throughout
    - Light grey background (`#F8F9FA`)
    - Blue header section (`#4285F4`) with white text
    - Material ripple effects with InkWell
    - Icon containers with blue tinted backgrounds
    - Destructive actions styled in red and orange
    - Proper dividers between sections

- **Accounts Screen Corporate Redesign and Transaction History**: Complete accounts management overhaul

  - **Corporate Banking UI**: Professional redesign of accounts screen with vertical card layout
    - Removed transaction history section from main accounts screen
    - Removed floating action button for transfers
    - Corporate banking aesthetic with white cards, subtle shadows, and borders
    - Total balance card displaying sum of all accounts
    - Account icons with color-coded circular backgrounds
    - Horizontal card layout with account name, type, and balance
    - Professional spacing and typography
  - **Unified Account Operations Form**: Combined form for balance adjustments and transfers
    - Operation type selector (Adjust Balance / Transfer Funds)
    - Adjust Balance mode: Account selection, amount input (+/-), reason field
    - Transfer mode: From/To account dropdowns, amount input, optional note
    - Real-time balance display for selected accounts
    - Form validation with error handling
    - Success/error feedback via snackbars
  - **View Account History Button**: Dedicated button to access transaction history
    - Full-width outlined button with icon
    - Navigates to comprehensive account history screen
  - **Account History Screen**: Complete transaction management interface
    - Period selector tabs (Day/Week/Month/Custom) with date range picker
    - Date navigator with previous/next buttons for period navigation
    - Transaction type filters: All, Expenditure, Earnings, Rides, Transfers, Fuel, Fees, Adjustments
    - Transactions grouped by date with headers (Today, Yesterday, dates)
    - Color-coded transaction cards with icons and metadata
    - Swipe-to-delete functionality with confirmation dialog
    - Delete reverses balance changes atomically
    - Empty states with filter clearing option
    - Pull-to-refresh support
  - **Backend Service Enhancements**: New methods for transaction management
    - `adjustAccountBalance()`: Manually adjust account balance with audit trail
    - `getAllAccountTransactions()`: Fetches and unifies ledger entries and transfers
    - `deleteTransaction()`: Deletes transaction and reverses balance changes
    - All new methods use proper error handling and logging

### Changed

- **Accounts Screen**: Complete redesign

  - Changed from grid layout (2 columns) to vertical list layout
  - Removed transaction history section from main view
  - Removed floating action button
  - Integrated account operations form directly on screen
  - Added total balance display at top
  - Modernized with corporate banking aesthetic

- **Comprehensive App Audit and Critical Fixes**: Major improvements for production readiness

  - **Memory Management**: Fixed memory leak from auth state listener in main.dart
    - Moved auth state listener to StatefulWidget with proper cleanup
    - Added session-based account initialization to prevent multiple initializations
  - **Atomic Transactions**: Implemented Firestore transactions for data integrity
    - Updated `transferBetweenAccounts()` to use atomic Firestore transactions
    - Updated `addRefuel()` to use atomic transactions for refuel records and ledger entries
    - Added `processRideTransactionsAtomically()` for ride updates with transaction reversal
    - All multi-step operations now use batch writes for consistency
  - **Enhanced Input Validation**: Comprehensive validation across all forms
    - Added payment split validation in edit ride screen
    - Added account selection validation for fee types
    - Added balance sufficiency checks before expense operations
    - Added warnings for negative balance scenarios
    - Added reasonable amount limits to prevent data entry errors
  - **Performance Optimizations**: Improved data loading efficiency
    - Added `getMultipleAccountBalances()` method using Firestore batch queries
    - Updated expense screen to use batch account balance loading
    - Reduced sequential database calls with parallel operations
  - **Debug Code Cleanup**: Removed production debug statements
    - Cleaned up debug print statements from rides history screen
    - Removed debug logging from fuel screen and new ride screen
    - Created `DebugLogger` utility for future debug logging needs
  - **Standardized Error Handling**: Centralized error management
    - Created `ErrorHandler` utility class with consistent error display
    - Standardized snackbar messages across all screens
    - Added confirmation dialogs for destructive operations
    - Added loading dialogs for async operations
    - Improved error message parsing for common failure scenarios

- **Expense Management System**: Complete expense tracking and management

  - New `ExpenseScreen` with comprehensive expense recording interface
  - **Expanded expense categories**: Added parkingFee, cigarettes, tea, water, food, goodies, cleaning, withdrawal, saving, rent
  - **Expense form with validation**: Account selection, category dropdown, amount input, description field, date picker
  - **Account balance display**: Account dropdown shows current balance for informed decision making
  - **Real-time expense history**: Display all expense transactions with category icons and account information
  - **Account integration**: Expenses automatically deduct from selected account balance
  - **Ledger integration**: All expenses recorded in ledger with proper categorization
  - **Pull-to-refresh functionality**: Update expense history with swipe gesture
  - **Consistent UI design**: Deep purple theme matching existing app design patterns
  - **Category icons**: Visual representation for each expense category
  - **Form validation**: Ensures account selection, category selection, and valid amount entry
  - **Success/error feedback**: User-friendly snackbar notifications for all operations
  - **Updated navigation**: Expense menu item in drawer now navigates to functional expense screen
  - **New `recordExpense()` method**: Added to AccountBalanceService for expense recording
  - **Enhanced TransactionCategory enum**: Added all requested expense categories with display names

- **Rides History Screen**: Comprehensive ride tracking and analytics system

  - New `RidesHistoryScreen` accessible from drawer menu with complete ride history functionality
  - **Statistics Dashboard**: Real-time display of total rides, total profit, average profit, and monthly statistics
  - **Advanced Filtering**: Date range picker, status filters (All/Completed/Cancelled), and search functionality
  - **Detailed Ride Cards**: Individual ride display with profit calculations, duration, distance, and performance metrics
  - **Debug Information Panel**: Troubleshooting tools showing ride counts, loading states, and data status
  - **Enhanced Empty States**: Contextual messages with refresh options and navigation back to home
  - **Comprehensive Ride Service Methods**: Added `getAllRides()`, `getCompletedRides()`, `getRidesByDateRange()`, and `getComprehensiveStatistics()`
  - **Date Formatting Support**: Added `intl` package dependency for proper date display and formatting
  - **Performance Optimizations**: Pagination support, caching, and efficient data loading patterns

- **Fuel Allocation Transfer System**: Complete fuel allocation management

  - New `PendingFuelAllocation` model to track accumulated fuel allocations from completed rides
  - **Dedicated Fuel Screen** (`FuelScreen`) with comprehensive fuel management interface
  - Real-time fuel allocation display on home screen with orange gradient card
  - Fuel transfer functionality with dedicated orange FAB and transfer screen
  - `FuelTransferScreen` with comprehensive transfer and adjustment options
  - `FuelAdjustmentScreen` for modifying allocation amounts
  - Transfer fuel allocation from any account to Fuel Reserve (axis_bank) account
  - Adjust fuel allocation (increase/decrease) with positive/negative amounts
  - Clear fuel allocation completely with confirmation dialog
  - Automatic fuel allocation saving when completing rides
  - Updated Firebase security rules and database documentation for new collection
  - Fixed Fuel menu item in drawer to navigate to dedicated fuel screen
  - Added debug functionality to create test fuel allocation data
  - **Moved all fuel-related functionality** from accounts screen to dedicated fuel screen
  - **Removed redundant floating action buttons** from fuel screen (functionality available in quick actions)
  - **Cleaned up fuel screen interface** by removing account balances overview section
  - **Removed debug fuel allocation button** from dashboard total balance card
  - **Added refuel tracking system** with kilometer and amount recording
    - New `RefuelScreen` with green-themed interface for recording fuel purchases
    - Input fields for kilometer reading and fuel amount with validation
    - **Automatic location fetching** using LocationService (same as rides)
    - **Dual storage system**: Records stored in both `refuels` collection and `ledger` collection
    - Automatic expense recording in ledger with fuel category
    - Deducts refuel amount from Fuel Reserve account balance
    - Includes informative note with kilometer reading for future statistics
    - Added refuel option to fuel section quick actions grid
    - **Uses existing Firestore security rules** (ledger collection already secured)
    - **New `refuels` collection** with detailed refuel records for statistics
    - **Updated Firestore rules** to include refuels collection security
    - **Fixed compilation errors** and enum completeness for fuel transactions

- **Accounts Management Screen**: Complete accounts management system

  - New accounts screen accessible from drawer menu
  - Real-time account balance display in 2x2 grid layout
  - Transfer money between accounts with validation
  - Transfer dialog with account selection, amount input, and optional notes
  - Pull-to-refresh functionality for account balances
  - Comprehensive error handling and user feedback

- **Enhanced Ledger System**: Improved transaction tracking
  - Added `TransactionNature` enum to distinguish transaction types (earning, expense, transfer, adjustment)
  - Updated `LedgerEntry` model with new `nature` field
  - Enhanced `AccountBalanceService` with `transferBetweenAccounts` method
  - Updated all existing transaction recording to include nature classification
  - Updated Firebase database documentation with new field structure

### Fixed

- **Location Service Issues**: Fixed starting location detection problems
  - Enhanced location permission handling with detailed error messages
  - Increased GPS timeout from 10 to 30 seconds for better reliability
  - Added comprehensive location readiness check before starting rides
  - Improved geocoding error handling with fallback coordinates
  - Added detailed debug logging throughout location service
  - Enhanced error messages for specific failure scenarios (permissions, GPS signal, network)
  - Added location readiness pre-check with user-friendly error dialogs
  - Implemented proper exception handling and re-throwing for better error propagation
  - **Fixed empty locality issue**: Enhanced locality determination logic to handle cases where placemark data returns empty locality names
  - **Simplified locality display**: Changed priority from most specific to general: street > subLocality > locality > administrativeArea
  - **Added empty locality validation**: Prevents rides from being created with empty startLocality
  - **Fixed active ride display**: Added fallback text for empty startLocality in active ride card
  - **Cleaned up debug information**: Removed all debug print statements and unnecessary logging from location service, ride service, and home screen
  - **Fixed RenderFlex overflow**: Added proper text overflow handling and maxLines constraints to prevent UI overflow issues in account cards and balance displays
  - **Fixed semantics assertion errors**: Restructured widget layout with proper Expanded/Flexible usage and added ValueKey to StreamBuilders to prevent parentDataDirty assertion failures

### Added

- App icons for all platforms (Android, iOS, macOS, Web)
- Favicon for web platform
- Firebase Core integration
- Firebase Authentication support
- Firebase Realtime Database support
- Google Services configuration for Android
- Google Sign-In authentication flow
- Login screen with Google authentication
- Home screen with financial dashboard
- Account management system with 4 predefined accounts
- Payment QR code screen with encouraging messaging
- Comprehensive balance card with integrated account breakdown
- **Ride Recording System**:
  - Complete ride lifecycle management (start, active, end, cancel)
  - Enhanced GPS location services with granular locality detection (area/neighborhood level)
  - Live ride timer with HH:MM:SS format
  - Comprehensive fee management with account selection
  - Split payment support across multiple accounts
  - Automatic calculation of metrics (Tip, Profit, Fuel Allocation, Profit Per KM/Min)
  - Real-time ride status updates on home screen
  - Active ride card with quick access to ride details
  - Location permissions for Android platform
  - Debug logging for detailed location information

### Changed

- Updated app title from "Flutter Demo" to "CabStats"
- Updated home page title to "CabStats Home"
- Replaced default Flutter icons with custom logo images across all platforms
- Added Firebase initialization in main.dart
- Updated Android build.gradle files with Google Services plugin
- Fixed Android NDK version compatibility for Firebase plugins
- Implemented authentication state management with StreamBuilder
- Created compact dashboard layout with horizontal account scrolling
- Integrated QR code button into total balance card
- Moved user avatar to app bar for space efficiency
- Consolidated all account information into single comprehensive balance card
- Redesigned account display as 2x2 grid within balance card
- Updated QR code image filename from PaymentQR.jpg to PaymentQR.png
- Updated QR code screen messaging to encourage tipping
- Updated account card display: "Main Account" as title, "Federal Bank" as subtitle, balance big and centered.
- Fixed RenderFlex overflow by adjusting grid aspect ratio and card content layout.
- **Enhanced Account Model**:
  - Added dropdown selection helper methods
  - Added account lookup by ID functionality
  - Added default account selection (Main Account/Federal Bank)
  - Added display name formatting for UI components
- **Updated Home Screen**:
  - Added real-time active ride monitoring with StreamBuilder
  - Integrated active ride card with live timer and quick access
  - Modified "Add New Ride" button to navigate to New Ride screen
  - Disabled ride creation when active ride exists

### Technical Details

- Moved `logo192.png` and `logo512.png` to appropriate platform-specific directories
- Updated Android mipmap icons in all density folders (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- Updated iOS AppIcon.appiconset with 1024x1024 icon
- Updated macOS AppIcon.appiconset with 512x512 and 1024x1024 icons
- Updated web platform icons (Icon-192.png, Icon-512.png) and favicon.png
- Moved `google-services.json` to `android/app/` directory
- Added Firebase dependencies: firebase_core, firebase_auth, firebase_database
- Configured Google Services plugin in Android build files
- Initialized Firebase in main.dart with async initialization
- Updated Android NDK version to 27.0.12077973 for Firebase compatibility
- Updated Java version to 17 in Android build.gradle.kts
- Adjusted `GridView.builder` `childAspectRatio` to `1.8` and card padding/font sizes to resolve RenderFlex overflow.
- **Ride Recording System Implementation**:
  - Added `geolocator: ^10.1.0` and `geocoding: ^2.1.1` dependencies for GPS functionality
  - Created comprehensive Ride model with payment splits and automatic calculations
  - Implemented LocationService for GPS coordinates and locality name conversion
  - Created RideService for Firebase Realtime Database operations
  - **Added navigation drawer** with Accounts, Rides, Fuel, and Expense menu options
  - **Cleaned up dashboard** by removing debug initialization button and rides history placeholder
  - **Removed manual account balance initialization** - now handled automatically during transactions
  - **Fixed account balance handling** to gracefully handle missing documents (assumes zero balance)
  - **Added automatic document creation** when updating non-existent account balances
  - **Enhanced account balance initialization** with detailed debug logging and error handling
  - **Added duplicate prevention** to avoid re-initializing existing account balances
  - **Added automatic account balance initialization** on app startup
  - **Added debug button** to manually initialize account balances for testing
  - **Updated Firestore security rules** to include account balances and ledger collections
  - **Fixed Ride model compilation errors** by adding missing calculated fields (tip, profit, fuelAllocation, profitPerKm, profitPerMin)
  - **Fixed compilation errors** in Account model (mutable balance) and Ride model (calculateMetrics method)
  - **Redesigned End Ride screen as step-by-step wizard** to fix overflow issues
  - **Created comprehensive Ledger system** for transaction history tracking
  - **Implemented Account Balance service** for real-time balance updates
  - **Added automatic transaction recording** for all fee deductions and payments
  - **Changed ride cancellation to completely delete** cancelled rides from database
  - **Fixed real-time duration updates** in active ride card using StreamBuilder
  - **Simplified ride recording flow** with single card on dashboard
  - **One-click ride start** directly from home screen with location detection
  - **Inline ride management** with Cancel/End buttons on active ride card
  - **Eliminated complex navigation** - no separate New Ride or Active Ride screens
  - Built EndRideScreen with comprehensive fee inputs and split payment support
  - Added location permissions (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) to AndroidManifest.xml
  - Integrated ride status monitoring into HomeScreen with StreamBuilder
  - **Fixed Firebase Realtime Database configuration** with proper database URL using `FirebaseDatabase.instanceFor()`
  - Added timeout handling for Firebase operations to prevent infinite loading
  - **Created Firebase Realtime Database security rules** for production and development environments
  - Added Firestore fallback service for improved reliability
  - Implemented automatic calculation formulas:
    - Tip = Amount Received - Fare - Platform Fee - Other Fee - Airport Fee - Toll Fee
    - Profit = Amount Received - Platform Fee - Other Fee - Airport Fee - Toll Fee
    - Fuel Allocation = Profit / 2
    - Profit Per KM = Profit / KM
    - Profit Per Min = Profit / Minutes
  - **Enhanced End Ride Wizard** with auto-focus and auto-advance functionality
  - **Added Ride Stats Screen** to display comprehensive ride summary after completion
  - **Improved user experience** with keyboard navigation and faster data entry
  - **Fixed dashboard account display** to show real-time account balances from database instead of hardcoded values
  - **Implemented efficient refresh mechanisms**: manual refresh button and pull-to-refresh (removed expensive streaming)
  - **Complete Ride Recording System** fully implemented with all core features:
    - GPS location tracking with locality detection
    - Real-time ride timer and status monitoring
    - Comprehensive fee management with account selection
    - Split payment support across multiple accounts
    - Automatic calculation of metrics (Tip, Profit, Fuel Allocation, Profit Per KM/Min)
    - Step-by-step ride ending wizard with auto-focus
    - Detailed ride statistics and performance metrics
    - Account balance integration with transaction logging

## [Unreleased]

### Added

- **Expense Stats Screen**: Complete expense tracking and analytics interface
  - Horizontal bar chart displaying expenses by category with percentages
  - Period filter with date navigator (Today, Week, Month, Custom)
  - Swipe-to-delete functionality for expenses with balance reversal
  - Add Expense quick access button in app bar
- **New Expense Category**: Tire Maintenance added to expense tracking

### Changed

- **Expense Screen**: Renamed from "Expense Management" to "Add Expense"
- **Other Fee Category**: Renamed to "Miscellaneous" for better clarity
- **Menu Drawer**: "Add Expense" renamed to "Expense Stats" with analytics focus

### Technical Details

- Horizontal bar chart replacing pie chart for better data visualization
- All categories displayed without limitation in expense breakdown
- Material Design 3 styling throughout expense screens
- Delete transaction method with atomic balance reversal
