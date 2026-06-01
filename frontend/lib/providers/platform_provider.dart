import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/platform.dart';
import '../models/account.dart';
import '../services/platform_service.dart';
import 'api_provider.dart';

class PlatformState {
  final List<Platform> platforms;
  final List<PlatformAccount> accounts;
  final bool isLoading;
  final String? error;

  PlatformState({this.platforms = const [], this.accounts = const [], this.isLoading = false, this.error});

  PlatformState copyWith({List<Platform>? platforms, List<PlatformAccount>? accounts, bool? isLoading, String? error}) {
    return PlatformState(
      platforms: platforms ?? this.platforms,
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PlatformNotifier extends StateNotifier<PlatformState> {
  final PlatformService _service;

  PlatformNotifier(this._service) : super(PlatformState());

  Future<void> loadPlatforms() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _service.getPlatforms();
      state = state.copyWith(
        platforms: data.map((j) => Platform.fromJson(j)).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAccounts({int? platformId}) async {
    try {
      final data = await _service.getAccounts(platformId: platformId);
      state = state.copyWith(
        accounts: data.map((j) => PlatformAccount.fromJson(j)).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> createAccount(Map<String, dynamic> data) async {
    try {
      await _service.createAccount(data);
      await loadAccounts();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> deleteAccount(int id) async {
    await _service.deleteAccount(id);
    await loadAccounts();
  }
}

final platformProvider = StateNotifierProvider<PlatformNotifier, PlatformState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final service = PlatformService(apiClient);
  final notifier = PlatformNotifier(service);
  notifier.loadPlatforms();
  notifier.loadAccounts();
  return notifier;
});
