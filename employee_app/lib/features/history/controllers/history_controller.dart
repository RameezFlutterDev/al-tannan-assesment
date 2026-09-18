import 'dart:async';

import 'package:get/get.dart';
import 'package:shared/shared.dart';

import '../../../data/repositories/attendance_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class HistoryController extends GetxController {
  final _attendanceRepository = AttendanceRepository();

  List<AttendanceDay> days = [];
  bool isLoading = true;
  StreamSubscription<List<AttendanceDay>>? _sub;

  @override
  void onInit() {
    super.onInit();
    final employeeId = Get.find<AuthController>().currentEmployee!.id;
    _sub = _attendanceRepository.historyStream(employeeId).listen((value) {
      days = value;
      isLoading = false;
      update();
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
