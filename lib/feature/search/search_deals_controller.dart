import 'dart:async';

import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/debouncer.dart';
import '../../util/log_service.dart';

class SearchDealsController extends GetxController {
  final DealRepo dealRepo;

  SearchDealsController({required this.dealRepo});

  final results = <DealModel>[].obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  final _debouncer = Debouncer();
  int _queryVersion = 0;

  bool _isCurrentQuery(int version) =>
      !isClosed && version == _queryVersion;

  void onQueryChanged(String query) {
    if (isClosed) return;

    // Invalidate older requests immediately.
    final version = ++_queryVersion;
    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      _debouncer.cancel();
      results.clear();
      hasSearched.value = false;
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    hasSearched.value = true;
    results.clear();

    _debouncer.run(() {
      unawaited(_search(trimmedQuery, version));
    });
  }

  Future<void> _search(String query, int version) async {
    if (!_isCurrentQuery(version)) return;

    try {
      final found = await dealRepo.search(query);

      if (!_isCurrentQuery(version)) return;

      results.assignAll(found);
    } catch (e) {
      if (!_isCurrentQuery(version)) return;

      LogService.error('search failed', e);
    } finally {
      if (_isCurrentQuery(version)) {
        isLoading.value = false;
      }
    }
  }

  @override
  void onClose() {
    ++_queryVersion;
    _debouncer.dispose();
    super.onClose();
  }
}