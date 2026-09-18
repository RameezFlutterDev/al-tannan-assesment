import 'dart:async';

import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/shift_repository.dart';

class ShiftsController extends GetxController {
  final _repository = ShiftRepository();

  List<Shift> shifts = [];
  bool isLoading = true;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _repository.streamAll().listen((value) {
      shifts = value;
      isLoading = false;
      update();
    });
  }

  Future<void> createShift(Shift shift) => _repository.create(shift);
  Future<void> updateShift(Shift shift) => _repository.update(shift);
  Future<void> setActive(String id, bool isActive) => _repository.setActive(id, isActive);

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
