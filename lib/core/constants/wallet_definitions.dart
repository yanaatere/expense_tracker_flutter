/// Predefined wallet options per type.
/// [logoAsset] is null until a per-wallet logo asset is added to the project.
class WalletOption {
  final String name;
  final String? logoAsset;

  const WalletOption({required this.name, this.logoAsset});
}

class WalletDefinitions {
  static const Map<String, List<WalletOption>> byType = {
    'Bank': [
      WalletOption(name: 'BCA'),
      WalletOption(name: 'Mandiri'),
      WalletOption(name: 'BRI'),
      WalletOption(name: 'BNI'),
      WalletOption(name: 'CIMB Niaga'),
      WalletOption(name: 'Danamon'),
      WalletOption(name: 'Permata'),
      WalletOption(name: 'BTN'),
      WalletOption(name: 'Other Bank'),
    ],
    'E-Wallet': [
      WalletOption(name: 'GoPay'),
      WalletOption(name: 'OVO'),
      WalletOption(name: 'DANA'),
      WalletOption(name: 'ShopeePay'),
      WalletOption(name: 'LinkAja'),
      WalletOption(name: 'PayPal'),
      WalletOption(name: 'Other'),
    ],
    'Credit': [
      WalletOption(name: 'BCA'),
      WalletOption(name: 'Mandiri'),
      WalletOption(name: 'BRI'),
      WalletOption(name: 'BNI'),
      WalletOption(name: 'CIMB Niaga'),
      WalletOption(name: 'Danamon'),
      WalletOption(name: 'Permata'),
      WalletOption(name: 'BTN'),
      WalletOption(name: 'Other Bank'),
    ],
    'Cash': [],
  };

  /// Sentinel values that trigger free-text input instead of a fixed name.
  static const Set<String> otherValues = {'Other Bank', 'Other'};

  static List<WalletOption> optionsFor(String type) =>
      byType[type] ?? [];
}
