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

  Future<CarModel> createCar({
    required String brand,
    required String fuelType,
    required String matricule,
    String status = 'AVAILABLE',
  }) async {
    final res = await dio.post(
      '/cars',
      data: {
        'brand': brand,
        'fuelType': fuelType,
        'matricule': matricule,
        'status': status,
      },
    );
    return CarModel.fromJson((res.data as Map).cast<String, dynamic>());
  }
}
