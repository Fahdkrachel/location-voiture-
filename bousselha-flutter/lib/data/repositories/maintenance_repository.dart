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
    String? startDate,
    String? description,
    String? endDate,
    required double cost,
  }) async {
    final data = <String, dynamic>{
      'carId': carId,
      'type': type,
      'cost': cost,
      'description': description,
      'endDate': endDate,
      'status': 'IN_PROGRESS',
    };
    if (startDate != null && startDate.isNotEmpty) {
      data['startDate'] = startDate;
    }
    final res = await dio.post(
      '/maintenance',
      data: data,
    );
    return MaintenanceModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<MaintenanceModel> updateMaintenance({
    required int id,
    required int carId,
    required String type,
    String? startDate,
    String? description,
    String? endDate,
    required double cost,
    required String status,
  }) async {
    final data = <String, dynamic>{
      'carId': carId,
      'type': type,
      'cost': cost,
      'description': description,
      'endDate': endDate,
      'status': status,
    };
    if (startDate != null && startDate.isNotEmpty) {
      data['startDate'] = startDate;
    }
    final res = await dio.put('/maintenance/$id', data: data);
    return MaintenanceModel.fromJson((res.data as Map).cast<String, dynamic>());
  }
}
