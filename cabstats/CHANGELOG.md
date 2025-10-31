# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2025-10-31

### Added

- Comprehensive README.md with project documentation, features, installation guide, and developer information
- **Expanded Usage Documentation**: Added detailed step-by-step usage guide covering:
  - Complete first launch instructions
  - Detailed ride management workflow (starting, during, ending rides)
  - Account and balance management instructions
  - Expense recording and analytics guide
  - Fuel management walkthrough
  - Tips management instructions
  - Analytics and reporting features
  - Advanced features (negative balances, offline-first)
  - Sync data instructions
  - Tips and best practices for daily use

### Changed

- **Fuel Management - Advance Refueling Support**: Removed restrictions that prevented fuel transfers and adjustments when there's no fuel allocation or when allocation is negative

  - Transfer Fuel and Adjust actions now work even when there's no pending allocation
  - Fuel allocation can go negative to support advance refueling scenarios
  - When there's no allocation, users can still transfer fuel and make adjustments for future refueling
  - Transfer amount "follows allocation" - pre-fills with allocation amount if available, otherwise allows manual entry
  - Negative allocations are displayed with red styling and labeled as "Advance Refueling"
  - UI clearly indicates when allocations are negative with helpful messaging

- **Negative Account Balance Support**: Removed all restrictions preventing accounts from going negative
  - Account transfers now allowed even when source account has insufficient balance
  - Expenses can be recorded even when account balance is insufficient (shows informational message)
  - Fuel transfers allowed even when source account balance is insufficient
  - All balance validation checks removed from UI and service layers
  - Users can now spend in advance and track negative balances for better financial planning

## [2.0.0] - 2025-10-31

### Added

- **Local-First Data Architecture**: Implemented comprehensive local-first data storage system with manual Firebase synchronization

  - Added Hive local storage system for offline-first operations
  - Created LocalStorageService for all data operations (rides, ledger, transfers, refuels, fuel allocation, tips, account balances)
  - Created SyncService with two-way sync and timestamp-based conflict resolution (newest wins)
  - Created NetworkService for connectivity detection
  - Created MigrationService to load existing Firebase data to local storage on first launch
  - Added `lastModified` timestamp field to all models (Ride, LedgerEntry, AccountTransfer, PendingFuelAllocation, Refuel, PendingTips, AccountBalance) for conflict resolution
  - Added Hive annotations and code generation for all data models
  - Manual sync functionality with conflict resolution indicator
  - Sync must be triggered manually from drawer or sync screen (automatic background sync is disabled)
  - Network security configuration for Jio and other carrier compatibility (explicitly allows Firebase/Google domains)
  - Timeout handling in sync operations (30s timeout with fallback to cache on network failures)
  - Fixed account balances stream to emit initial values immediately (no more loading spinner on app startup)
  - Reset All Data now deletes from both local storage and Firestore (was only local before)

- Comprehensive code review report (`CODE_REVIEW_REPORT.md`) documenting 20+ issues including critical bugs, code quality problems, and recommendations for improvements.
- Pending Tips: running total, Home dashboard card, and transfer to Savings from Main Account as an expense. Added service methods and ride completion accumulation.

### Changed

- **RideService**: Refactored to use LocalStorageService instead of direct Firestore calls

  - All ride operations now work locally and sync manually
  - Faster ride operations with no network latency
  - Active ride monitoring uses local storage streams

- **AccountBalanceService**: Refactored to use LocalStorageService instead of direct Firestore calls

  - All balance operations work locally
  - Transactions, transfers, expenses, and refuels stored locally
  - Real-time updates via local storage streams
  - Removed Firestore transactions in favor of local atomic operations

- **Main App Initialization**: Updated to initialize Hive and run data migration on first launch

  - Hive initialized before app start
  - Automatic migration from Firebase to local storage for existing users
  - Seamless transition with no data loss
  - Sync must be triggered manually (automatic background sync disabled)

- Fuel allocation during ride save is now calculated as 50% of fare (was ₹12/km). Updated logic in `Ride.calculateFuelAllocation()`, `Ride.calculateMetrics()`, `EditRideScreen` summary and save flow, and `EndRideWizardScreen` metrics preview.
- Profit-per metrics now derived from fare only: `profitPerKm = fare / km`, `profitPerMin = fare / minutes` (was based on profit). Implemented in `Ride` model and wizard preview calculations.

### Fixed

- Prevent crash when ending ride with empty ride ID by resolving the active ride document ID in `RideService.endRide()`.
- Ensure `Ride.id` is always populated by injecting Firestore `doc.id` when reading rides in `RideService` (active ride, history, streams, completed rides, by date, and get by ID).

- **Expense Stats Screen Bug Fixes**: Fixed all 13 bugs in the expense stats screen

  - **BUG #1**: Fixed date filtering logic - Changed from exclusive date comparisons to inclusive date range filtering using `isAtSameMomentAs` and proper `isAfter`/`isBefore` combinations to ensure boundary dates are included
  - **BUG #2**: Fixed "Today" period calculation - Now sets end date to end of day (23:59:59) instead of current moment, showing full day expenses
  - **BUG #3**: Fixed week period display across months - Added logic to detect when week spans multiple months and display both month names (e.g., "28 Jan - 3 Feb")
  - **BUG #4**: Fixed week navigation end date calculation - Now correctly calculates 7-day period with proper time components (days: 6, hours: 23, minutes: 59, seconds: 59)
  - **BUG #5**: Fixed month navigation with year boundary - Added handling for December-to-January transitions to prevent month overflow errors
  - **BUG #6**: Fixed "Today" navigation end dates - Now sets end date to end of day (23:59:59) when navigating previous/next days
  - **BUG #7**: Removed unused account filter code - Deleted `_selectedAccountId` variable and filter logic since no UI exists to set it
  - **BUG #8**: Removed unused account balance loading - Deleted `_accountBalances` variable and `_loadAccountBalances` method to eliminate unnecessary API calls
  - **BUG #9**: Removed unused top category method - Deleted `_getTopCategory()` method that was never called
  - **BUG #10**: Fixed division by zero in percentage calculation - Added check for `totalExpenses > 0` before calculating percentages and showing breakdown
  - **BUG #11**: Fixed week navigation boundary logic - Corrected navigation checks to prevent navigating to future dates
  - **BUG #12**: Enabled custom period forward navigation - Added logic to allow forward navigation for custom periods when not at current date
  - **BUG #13**: Added mounted checks in error handlers - Added `if (mounted)` checks before setState in all catch blocks to prevent errors when widget is disposed

- **Transfer Section Bug Fixes**: Fixed multiple critical bugs in account transfer functionality

  - **BUG #1**: Added missing "To" account validation - Form now validates that destination account is selected before submission
  - **BUG #2**: Fixed account balance document existence checks - Now ensures both source and destination account documents exist before attempting transfer
  - **BUG #3**: Added Firestore transaction atomicity - Transfer now uses atomic Firestore transactions to ensure balances are updated correctly or not at all
  - **BUG #4**: Fixed transfer record creation timing - Transfer record is now created within the transaction to prevent orphaned records
  - **BUG #5**: Added balance display for destination account - "To" account now shows current balance so users can see destination balance
  - **BUG #6**: Added dropdown form validation - Dropdown fields now validate that a selection has been made
  - **BUG #7**: Enhanced error handling with specific error messages - Better feedback for insufficient balance, missing accounts, and network errors
  - **BUG #8**: Fixed balance refresh timing - Balances are now reloaded immediately after successful transfer before closing the form
  - **BUG #9**: Added comprehensive pre-validation - Client-side validation for amount, account selection, and sufficient balance before attempting server operation
  - **BUG #10**: Improved user feedback with detailed error messages showing available balance when transfer fails
  - **BUG #11**: Fixed "To" accounts list and balance not updating when "From" account changes - Added ValueKey to "To" dropdown to force widget rebuild when "From" account changes, ensuring the dropdown shows the correct available accounts
  - **BUG #12**: Fixed modal bottom sheet not updating form state - Added StatefulBuilder to modal bottom sheet and reset form state when opening, ensuring dropdown selections and balances update properly when changing accounts

- **Expense Stats Screen Bug Fixes**: Fixed all 13 bugs in the expense stats screen

  - **BUG #1**: Fixed date filtering logic - Changed from exclusive date comparisons to inclusive date range filtering using `isAtSameMomentAs` and proper `isAfter`/`isBefore` combinations to ensure boundary dates are included
  - **BUG #2**: Fixed "Today" period calculation - Now sets end date to end of day (23:59:59) instead of current moment, showing full day expenses
  - **BUG #3**: Fixed week period display across months - Added logic to detect when week spans multiple months and display both month names (e.g., "28 Jan - 3 Feb")
  - **BUG #4**: Fixed week navigation end date calculation - Now correctly calculates 7-day period with proper time components (days: 6, hours: 23, minutes: 59, seconds: 59)
  - **BUG #5**: Fixed month navigation with year boundary - Added handling for December-to-January transitions to prevent month overflow errors
  - **BUG #6**: Fixed "Today" navigation end dates - Now sets end date to end of day (23:59:59) when navigating previous/next days
  - **BUG #7**: Removed unused account filter code - Deleted `_selectedAccountId` variable and filter logic since no UI exists to set it
  - **BUG #8**: Removed unused account balance loading - Deleted `_accountBalances` variable and `_loadAccountBalances` method to eliminate unnecessary API calls
  - **BUG #9**: Removed unused top category method - Deleted `_getTopCategory()` method that was never called
  - **BUG #10**: Fixed division by zero in percentage calculation - Added check for `totalExpenses > 0` before calculating percentages and showing breakdown
  - **BUG #11**: Fixed week navigation boundary logic - Corrected navigation checks to prevent navigating to future dates
  - **BUG #12**: Enabled custom period forward navigation - Added logic to allow forward navigation for custom periods when not at current date
  - **BUG #13**: Added mounted checks in error handlers - Added `if (mounted)` checks before setState in all catch blocks to prevent errors when widget is disposed

- **Critical Bug Fix**: Fixed refuel balance calculation bug where fuel expenses were incorrectly adding to the Fuel Reserve balance instead of deducting from it. The issue was in the `addRefuel` method where a negative cost value was being passed to `addTransaction`, causing the balance calculation to add instead of subtract. Changed from passing `-cost` to passing `cost` with the correct `TransactionType.debit` type.

- **Bug #1**: Fixed metrics calculation timing - `calculateMetrics()` now called after `endTime` is set in the ride wizard, preventing division by zero errors in profit-per-minute calculations.

- **Bug #2**: Fixed incorrect fee categorization - All fees in `processRideTransactions()` were being categorized as `tollFee`. Now properly distinguishes between tollFee, platformFee, airportFee, and otherFee categories based on the fee type mapping.

- **Bug #3**: Fixed missing transaction processing in old end ride screen - The `end_ride_screen.dart` now processes account transactions just like the wizard screen, ensuring balances are always updated when ending rides.

- **Bug #4**: Fixed incorrect fee category mapping in atomic transactions - Replaced hardcoded account-based fee category mapping with proper fee type-based categorization that correctly maps fee types to their respective transaction categories.

- **Bug #5**: Fixed missing support for negative fees (adjustments) - Changed fee processing logic to accept `!= 0` instead of `> 0`, allowing negative values for refunds, adjustments, and corrections. Balance updates now properly handle both positive and negative amounts.

- **Bug #6**: Added check for existing active ride before starting new ride - Prevents creating multiple active rides which can cause inconsistent state. Now throws exception if user tries to start a ride while another is active.

- **Bug #7**: Fixed duplicate document ID update in startRide - Removed redundant docRef.update() call that was updating the document unnecessarily. Also fixed to properly update startTime in Firestore milliseconds format.

- **Bug #8**: Fixed async error in atomic transaction - Moved reverseRideTransactions() call outside the Firestore transaction since it performs Firestore reads which are not allowed inside transactions. This was causing transaction failures.

- **Bug #9**: Changed fuel allocation calculation from profit/2 to 12 rupees per km - Updated fuel allocation calculation to use a fixed rate of ₹12 per kilometer instead of being half of profit. This provides more predictable fuel allocation regardless of profit margins.

- **Bug #10**: Added ensureAccountBalanceExists for fee accounts in atomic transactions - Now ensures fee account balance documents exist before updating balances, preventing transaction failures when updating rides.

- **Bug #11**: Fixed using set with merge in Firestore transaction - Changed from transaction.set() with SetOptions(merge: true) to transaction.update() for updating ride document. This is the correct approach for partial updates within a transaction.

- **Bug #12**: Fixed missing TransactionCategory import - Added missing import for TransactionCategory enum in edit_ride_screen.dart to fix compilation errors.

- **Bug #13**: Fixed location display showing only lat/lng coordinates - Improved geocoding logic to build comprehensive location strings using all available address components (street, subLocality, locality, administrativeArea, country, postalCode). Now displays proper addresses instead of just coordinates. If address components are unavailable, it falls back to coordinates in format: "lat, lng" without the "Location" prefix.

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

- Firestore rules: allow nested writes under `users/{uid}/pendingTips/**` so transferring Pending Tips can append history within a transaction.

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
