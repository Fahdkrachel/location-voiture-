import 'package:dio/dio.dart';

import '../models/car_model.dart';

class CarRepository {
  final Dio dio;
  CarRepository(this.dio);

  Future<List<CarModel>> getCars() async {
    final res = await dio.get('/cars');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(CarModel.fromJson).toList();
  }

  Future<List<CarModel>> getAvailableCars() async {
    final res = await dio.get('/cars/available');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(CarModel.fromJson).toList();
  }

  Future<CarModel> createCar({
    required String brand,
    required String fuelType,
    required String matricule,
    String? nextInspectionDate,
    String? lastOilChangeDate,
    String? insuranceExpiryDate,
    String? imagePath,
    String status = 'AVAILABLE',
  }) async {
    final formData = FormData.fromMap({
      'brand': brand,
      'fuelType': fuelType,
      'matricule': matricule,
      'nextInspectionDate': nextInspectionDate,
      'lastOilChangeDate': lastOilChangeDate,
      'insuranceExpiryDate': insuranceExpiryDate,
      'status': status,
      if (imagePath != null && imagePath.isNotEmpty)
        'image': await MultipartFile.fromFile(imagePath),
    });
    final res = await dio.post(
      '/cars',
      data: formData,
    );
    return CarModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<CarModel> updateCar({
    required int id,
    required String brand,
    required String fuelType,
    required String matricule,
    String? nextInspectionDate,
    String? lastOilChangeDate,
    String? insuranceExpiryDate,
    String? imagePath,
    required String status,
  }) async {
    final formData = FormData.fromMap({
      'brand': brand,
      'fuelType': fuelType,
      'matricule': matricule,
      'nextInspectionDate': nextInspectionDate,
      'lastOilChangeDate': lastOilChangeDate,
      'insuranceExpiryDate': insuranceExpiryDate,
      'status': status,
      if (imagePath != null && imagePath.isNotEmpty)
        'image': await MultipartFile.fromFile(imagePath),
    });
    final res = await dio.put(
      '/cars/$id',
      data: formData,
    );
    return CarModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<void> deleteCar(int id) async {
    await dio.delete('/cars/$id');
  }
}
