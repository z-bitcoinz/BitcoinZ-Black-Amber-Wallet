import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../providers/wallet_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';

class DesktopMainScreen extends StatefulWidget {
  const DesktopMainScreen({super.key});

  @override
  State<DesktopMainScreen> createState() => _DesktopMainScreenState();
}

class _DesktopMainScreenState extends State<DesktopMainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Custom title bar
          _buildTitleBar(),
          // Main content
          Expanded(
            child: Consumer2<AuthProvider, WalletProvider>(
              builder: (context, authProvider, walletProvider, child) {
                if (authProvider.needsSetup) {
                  return _buildSetupScreen();
                } else if (authProvider.needsAuthentication) {
                  return _buildAuthScreen();
                } else if (authProvider.isAuthenticated && !walletProvider.hasWallet) {
                  return _buildWalletSetupScreen();
                } else {
                  return _buildMainContent();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      height: 32,
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: MoveWindow(
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  'BitcoinZ Desktop Wallet',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
          ),
          Row(
            children: [
              MinimizeWindowButton(
                colors: WindowButtonColors(
                  iconNormal: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              MaximizeWindowButton(
                colors: WindowButtonColors(
                  iconNormal: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              CloseWindowButton(
                colors: WindowButtonColors(
                  iconNormal: Colors.red,
                ),
                onPressed: () {
                  appWindow.hide();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 64),
          SizedBox(height: 16),
          Text(
            'Welcome to BitcoinZ Desktop Wallet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Set up your wallet to get started'),
          SizedBox(height: 32),
          // TODO: Add setup buttons
        ],
      ),
    );
  }

  Widget _buildAuthScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64),
          SizedBox(height: 16),
          Text(
            'Welcome Back',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Authenticate to access your wallet'),
          SizedBox(height: 32),
          // TODO: Add authentication UI
        ],
      ),
    );
  }

  Widget _buildWalletSetupScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_circle_outline, size: 64),
          SizedBox(height: 16),
          Text(
            'Create Your Wallet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Create a new wallet or restore from seed phrase'),
          SizedBox(height: 32),
          // TODO: Add wallet creation UI
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Row(
      children: [
        // Sidebar navigation
        _buildSidebar(),
        // Main content area
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: [
              _buildDashboardPage(),
              _buildSendPage(),
              _buildReceivePage(),
              _buildTransactionsPage(),
              _buildSettingsPage(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Wallet info
          Container(
            padding: const EdgeInsets.all(16),
            child: Consumer<WalletProvider>(
              builder: (context, walletProvider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatBtcz(walletProvider.balance.total),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (walletProvider.isSyncing)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1),
                          )
                        else
                          Icon(
                            Icons.check_circle,
                            size: 12,
                            color: Colors.green,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          walletProvider.isSyncing ? 'Syncing...' : 'Synced',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(),
          // Navigation items
          Expanded(
            child: ListView(
              children: [
                _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                _buildNavItem(Icons.send, 'Send', 1),
                _buildNavItem(Icons.call_received, 'Receive', 2),
                _buildNavItem(Icons.list, 'Transactions', 3),
                const Divider(),
                _buildNavItem(Icons.settings, 'Settings', 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  Widget _buildDashboardPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              // Balance cards
              Row(
                children: [
                  Expanded(
                    child: _buildBalanceCard(
                      'Total Balance',
                      walletProvider.balance.total,
                      Icons.account_balance_wallet,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBalanceCard(
                      'Transparent',
                      walletProvider.balance.transparent,
                      Icons.visibility,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBalanceCard(
                      'Shielded',
                      walletProvider.balance.shielded,
                      Icons.security,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Recent transactions
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: ListView.builder(
                    itemCount: walletProvider.recentTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = walletProvider.recentTransactions[index];
                      return ListTile(
                        leading: Icon(
                          tx.isSent ? Icons.arrow_upward : Icons.arrow_downward,
                          color: tx.isSent ? Colors.red : Colors.green,
                        ),
                        title: Text(tx.displayAmount),
                        subtitle: Text(tx.formattedDate),
                        trailing: Text(tx.confirmationStatus),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(String title, double amount, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.formatBtcz(amount),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendPage() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Send BitcoinZ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          Text('Send functionality will be implemented here'),
        ],
      ),
    );
  }

  Widget _buildReceivePage() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Receive BitcoinZ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          Text('Receive functionality will be implemented here'),
        ],
      ),
    );
  }

  Widget _buildTransactionsPage() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transaction History', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          Text('Transaction history will be implemented here'),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return const Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          Text('Settings will be implemented here'),
        ],
      ),
    );
  }
}