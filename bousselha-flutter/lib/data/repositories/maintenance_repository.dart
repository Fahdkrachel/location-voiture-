import 'package:dio/dio.dart';

import '../models/maintenance_model.dart';

class MaintenanceRepository {
  final Dio dio;
  MaintenanceRepository(this.dio);

  Future<List<MaintenanceModel>> getMaintenance() async {
    final res = await dio.get('/maintenance');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(MaintenanceModel.fromJson).toList();
  }

  Future<MaintenanceModel> createMaintenance({
    required int carId,
    required String type,
    required String startDate,
    String? description,
    String? endDate,
    double? cost,
  }) async {
    final res = await dio.post(
      '/maintenance',
      data: {
        'carId': carId,
        'type': type,
        'startDate': startDate,
        'description': description,
        'endDate': endDate,
        'cost': cost,
      },
    );
    return MaintenanceModel.fromJson((res.data as Map).cast<String, dynamic>());
  }
}
