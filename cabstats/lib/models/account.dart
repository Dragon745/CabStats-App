class Account {
  final String id;
  final String name;
  final String type;
  double balance;
  final String icon;
  final String color;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.icon,
    required this.color,
  });

  // Sample data for the 4 accounts
  static List<Account> getSampleAccounts() {
    return [
      Account(
        id: 'federal_bank',
        name: 'Main Account',
        type: 'Federal Bank',
        balance: 12500.00,
        icon: '🏦',
        color: '0xFF1976D2', // Blue
      ),
      Account(
        id: 'axis_bank',
        name: 'Fuel Reserve',
        type: 'Axis Bank',
        balance: 3500.00,
        icon: '⛽',
        color: '0xFF388E3C', // Green
      ),
      Account(
        id: 'cash',
        name: 'Cash Wallet',
        type: 'Physical Cash',
        balance: 2500.00,
        icon: '💵',
        color: '0xFFF57C00', // Orange
      ),
      Account(
        id: 'platform_wallets',
        name: 'Digital Wallets',
        type: 'Platform Wallets',
        balance: 1800.00,
        icon: '📱',
        color: '0xFF7B1FA2', // Purple
      ),
    ];
  }

  // Calculate total balance
  static double getTotalBalance(List<Account> accounts) {
    return accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  // Get account by ID
  static Account? getAccountById(List<Account> accounts, String id) {
    try {
      return accounts.firstWhere((account) => account.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get default account (Main Account/Federal Bank)
  static Account getDefaultAccount(List<Account> accounts) {
    return getAccountById(accounts, 'federal_bank') ?? accounts.first;
  }

  // Get accounts formatted for dropdown
  static List<Map<String, dynamic>> getAccountsForDropdown(List<Account> accounts) {
    return accounts.map((account) => {
      'value': account.id,
      'label': '${account.icon} ${account.name} (${account.type})',
      'account': account,
    }).toList();
  }

  // Get account display name for dropdown
  String get displayName => '$icon $name ($type)';

  // Get account balance from Firebase (if using real-time balances)
  static Future<double> getAccountBalance(String accountId) async {
    // This would typically call AccountBalanceService
    // For now, return the static balance
    final accounts = getSampleAccounts();
    final account = accounts.firstWhere((a) => a.id == accountId, orElse: () => accounts.first);
    return account.balance;
  }

  // Update account balance (for real-time updates)
  static Future<void> updateAccountBalance(String accountId, double newBalance) async {
    // This would typically call AccountBalanceService
    // For now, just update the static balance
    final accounts = getSampleAccounts();
    final accountIndex = accounts.indexWhere((a) => a.id == accountId);
    if (accountIndex != -1) {
      accounts[accountIndex].balance = newBalance;
    }
  }
}
