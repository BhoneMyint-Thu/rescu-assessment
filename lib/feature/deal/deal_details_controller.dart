import 'package:get/get.dart';

import '../../model/deal_model.dart';
import '../../repository/deal_repo.dart';
import '../../service/analytics_service.dart';
import '../../service/api_exception.dart';
import '../../service/cart_service.dart';
import '../../util/log_service.dart';

class DealDetailsController extends GetxController {
  final DealRepo dealRepo;
  final CartService cartService;
  final AnalyticsService analytics;

  DealDetailsController({
    required this.dealRepo,
    required this.cartService,
    required this.analytics,
  });

  final _deal = Rxn<DealModel>();
  DealModel? get deal => _deal.value;

  final isLoading = false.obs;
  final errorMessage = RxnString();

  final _quantityLeft = RxnInt();
  int? get quantityLeft => _quantityLeft.value;

  Worker? _cartWorker;
  int? _dealId;
  String _source = 'unknown';

  @override
  void onInit() {
    super.onInit();
    final argument = Get.arguments;
    _dealId = int.tryParse(Get.parameters['id'] ?? '');
    _source = Get.parameters['source'] ?? 'unknown';

    if (argument is DealModel && (_dealId == null || argument.id == _dealId)) {
      _setDeal(argument);
    } else {
      loadDeal();
    }
  }

  Future<void> loadDeal() async {
    if (isClosed || isLoading.value || deal != null) return;

    final id = _dealId;
    if (id == null || id <= 0) {
      errorMessage.value = 'This deal link is invalid.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;
    try {
      final loaded = await dealRepo.fetchById(id);
      if (isClosed) return;
      _setDeal(loaded);
    } catch (e) {
      if (isClosed) return;
      LogService.error('load deal $id failed', e);
      errorMessage.value = e is ApiException && e.statusCode == 404
          ? 'This deal is no longer available.'
          : 'Could not load this deal. Please try again.';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }

  void _setDeal(DealModel loaded) {
    _quantityLeft.value = loaded.quantityLeft;
    _deal.value = loaded;
    analytics.logEvent('deal_details_view', {
      'deal_id': loaded.id,
      'source': _source,
    });
    // Whenever the cart changes, re-check this deal's remaining stock so the
    // details screen never shows stale availability.
    _cartWorker = ever(cartService.itemCount, (_) => _recheckAvailability());
  }

  Future<void> _recheckAvailability() async {
    final currentDeal = deal;
    if (isClosed || currentDeal == null) return;
    LogService.log('re-checking availability for deal ${currentDeal.id}');
    final fresh = await dealRepo.fetchById(currentDeal.id);
    if (isClosed) return;
    _quantityLeft.value = fresh.quantityLeft;
  }

  void addToCart() {
    final currentDeal = deal;
    if (isClosed || currentDeal == null) return;
    cartService.add(currentDeal);
    Get.snackbar(
      'Added to bag',
      '${currentDeal.name} — pick up ${currentDeal.pickupWindow.label}',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void onClose() {
    _cartWorker?.dispose();
    super.onClose();
  }
}
