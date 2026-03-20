import '../models/wallet.dart';

abstract class WalletRepository {
  Future<List<Wallet>> getWallets();

  Future<Wallet> createWallet({
    required String name,
    required String type,
    required String currency,
    required double balance,
    String? goals,
  });
}
