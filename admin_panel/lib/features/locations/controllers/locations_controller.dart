import 'dart:async';

import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/location_repository.dart';

class LocationsController extends GetxController {
  final _repository = LocationRepository();

  List<WorkLocation> locations = [];
  bool isLoading = true;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _repository.streamAll().listen((value) {
      locations = value;
      isLoading = false;
      update();
    });
  }

  Future<void> createLocation(WorkLocation location) => _repository.create(location);
  Future<void> updateLocation(WorkLocation location) => _repository.update(location);
  Future<void> setActive(String id, bool isActive) => _repository.setActive(id, isActive);

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
