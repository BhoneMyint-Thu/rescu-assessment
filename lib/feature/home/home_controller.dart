import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../util/log_service.dart';

class HomeController extends GetxController {
  final DealRepo dealRepo;

  HomeController({required this.dealRepo});

  final deals = <DealModel>[].obs;
  final flashDeals = <DealModel>[].obs;
  final isLoading = true.obs;
  final todayOnly = false.obs;
  final showAppBarShadow = false.obs;
  final showScrollToTopButton = false.obs;

  final scrollController = ScrollController();
  final refreshController = RefreshController();

  int _page = 1;
  int _totalPages = 1;
  bool _isFetchingMore = false;
  int _feedVersion = 0;
  bool _isRefreshing = false;
  bool _isCurrentFeed(int version) => !isClosed && version == _feedVersion;

  bool get hasMore => _page < _totalPages;

  List<DealModel> get visibleDeals => todayOnly.value
      ? deals.where((d) => d.pickupWindow.isToday).toList()
      : deals.toList();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    _initialLoad();
  }

  void _onScroll() {
    final offset = scrollController.offset;
    showAppBarShadow.value = offset > 4;
    showScrollToTopButton.value = offset > 800;
  }

  Future<void> _initialLoad() async {
    isLoading.value = true;
    try {
      await Future.wait([refreshDeals(), _loadFlashDeals()]);
    } catch (e) {
      LogService.error('initial load failed', e);
    }
    isLoading.value = false;
  }

  Future<void> _loadFlashDeals() async {
    flashDeals.assignAll(await dealRepo.fetchFlashDeals());
  }

  Future<void> refreshDeals() async {
    if (isClosed) return;
    final version = ++_feedVersion;
    _isRefreshing = true;
    _isFetchingMore = false;
    refreshController.loadComplete();

    try {
      final res = await dealRepo.fetchDeals(page: 1);

      if (!_isCurrentFeed(version)) return;

      _page = 1;
      _totalPages = res.totalPages;
      deals.assignAll(res.items);

      refreshController.refreshCompleted(resetFooterState: true);
    } catch (e) {
      if (!_isCurrentFeed(version)) return;

      LogService.error('refreshDeals failed', e);
      refreshController.refreshFailed();
    } finally {
      if (_isCurrentFeed(version)) {
        _isRefreshing = false;
      }
    }
    // _page = 1;
    // final res = await dealRepo.fetchDeals(page: 1);
    // _totalPages = res.totalPages;
    // deals.assignAll(res.items);
    // refreshController.refreshCompleted();
  }

  Future<void> loadMore() async {
    if (isClosed || _isFetchingMore) return;
    if (_isRefreshing) {
      refreshController.loadComplete();
      return;
    }
    if (!hasMore) {
      refreshController.loadNoData();
      return;
    }
    final version = _feedVersion;
    final nextPage = _page + 1;
    _isFetchingMore = true;
    try {
      final res = await dealRepo.fetchDeals(page: nextPage);
      if (!_isCurrentFeed(version)) return;
      _page = nextPage;
      _totalPages = res.totalPages;
      deals.addAll(res.items);
    } catch (e) {
      if (!_isCurrentFeed(version)) return;

      LogService.error('loadMore failed', e);
    } finally {
      if (_isCurrentFeed(version)) {
        _isFetchingMore = false;
        refreshController.loadComplete();
      }
    }
    // try {
    //   final res = await dealRepo.fetchDeals(page: _page);
    //   _totalPages = res.totalPages;
    //   deals.addAll(res.items);
    // } catch (e) {
    //   LogService.error('loadMore failed', e);
    //   _page--;
    // }
    // _isFetchingMore = false;
    // refreshController.loadComplete();
  }

  void scrollToTop() {
    scrollController.animateTo(0,
        duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
  }

  @override
  void onClose() {
    ++_feedVersion;
    scrollController.dispose();
    refreshController.dispose();
    super.onClose();
  }
}
