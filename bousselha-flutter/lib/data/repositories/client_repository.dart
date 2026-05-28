import 'package:dio/dio.dart';

import '../models/client_model.dart';

class ClientRepository {
  final Dio dio;
  ClientRepository(this.dio);

  Future<List<ClientModel>> getClients() async {
    final res = await dio.get('/clients');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(ClientModel.fromJson).toList();
  }

  Future<ClientModel> getClientById(int id) async {
    final res = await dio.get('/clients/$id');
    return ClientModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<ClientModel> createClient({
    required String fullName,
    required String cinNumber,
    required String phone,

    String? birthDate,
    String? addressMorocco,
    String? addressAbroad,
    String? profession,
    String? drivingLicenseNumber,
    String? drivingLicenseIssuedAt,
    String? passportNumber,
    String? passportIssuedAt,

    String? additionalDriverFullName,
    String? additionalDriverDrivingLicenseNumber,
    String? additionalDriverDrivingLicenseIssuedAt,
    String? additionalDriverPassportNumber,
  }) async {
    final payload = _payload(
      fullName: fullName,
      cinNumber: cinNumber,
      phone: phone,
      birthDate: birthDate,
      addressMorocco: addressMorocco,
      addressAbroad: addressAbroad,
      profession: profession,
      drivingLicenseNumber: drivingLicenseNumber,
      drivingLicenseIssuedAt: drivingLicenseIssuedAt,
      passportNumber: passportNumber,
      passportIssuedAt: passportIssuedAt,
      additionalDriverFullName: additionalDriverFullName,
      additionalDriverDrivingLicenseNumber: additionalDriverDrivingLicenseNumber,
      additionalDriverDrivingLicenseIssuedAt: additionalDriverDrivingLicenseIssuedAt,
      additionalDriverPassportNumber: additionalDriverPassportNumber,
    );
    final res = await dio.post(
      '/clients',
      data: payload,
    );
    return ClientModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<ClientModel> updateClient({
    required int id,
    required String fullName,
    required String cinNumber,
    required String phone,
    String? birthDate,
    String? addressMorocco,
    String? addressAbroad,
    String? profession,
    String? drivingLicenseNumber,
    String? drivingLicenseIssuedAt,
    String? passportNumber,
    String? passportIssuedAt,
    String? additionalDriverFullName,
    String? additionalDriverDrivingLicenseNumber,
    String? additionalDriverDrivingLicenseIssuedAt,
    String? additionalDriverPassportNumber,
  }) async {
    final payload = _payload(
      fullName: fullName,
      cinNumber: cinNumber,
      phone: phone,
      birthDate: birthDate,
      addressMorocco: addressMorocco,
      addressAbroad: addressAbroad,
      profession: profession,
      drivingLicenseNumber: drivingLicenseNumber,
      drivingLicenseIssuedAt: drivingLicenseIssuedAt,
      passportNumber: passportNumber,
      passportIssuedAt: passportIssuedAt,
      additionalDriverFullName: additionalDriverFullName,
      additionalDriverDrivingLicenseNumber: additionalDriverDrivingLicenseNumber,
      additionalDriverDrivingLicenseIssuedAt: additionalDriverDrivingLicenseIssuedAt,
      additionalDriverPassportNumber: additionalDriverPassportNumber,
    );
    final res = await dio.put('/clients/$id', data: payload);
    return ClientModel.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<void> deleteClient(int id) async {
    await dio.delete('/clients/$id');
  }

  Map<String, dynamic> _payload({
    required String fullName,
    required String cinNumber,
    required String phone,
    String? birthDate,
    String? addressMorocco,
    String? addressAbroad,
    String? profession,
    String? drivingLicenseNumber,
    String? drivingLicenseIssuedAt,
    String? passportNumber,
    String? passportIssuedAt,
    String? additionalDriverFullName,
    String? additionalDriverDrivingLicenseNumber,
    String? additionalDriverDrivingLicenseIssuedAt,
    String? additionalDriverPassportNumber,
  }) {
    String? trimOrNull(String? value) {
      final v = value?.trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    return {
      'fullName': fullName.trim(),
      'cinNumber': cinNumber.trim(),
      'phone': phone.trim(),
      'birthDate': trimOrNull(birthDate),
      'addressMorocco': trimOrNull(addressMorocco),
      'addressAbroad': trimOrNull(addressAbroad),
      'profession': trimOrNull(profession),
      'drivingLicenseNumber': trimOrNull(drivingLicenseNumber),
      'drivingLicenseIssuedAt': trimOrNull(drivingLicenseIssuedAt),
      'passportNumber': trimOrNull(passportNumber),
      'passportIssuedAt': trimOrNull(passportIssuedAt),
      'additionalDriverFullName': trimOrNull(additionalDriverFullName),
      'additionalDriverDrivingLicenseNumber': trimOrNull(additionalDriverDrivingLicenseNumber),
      'additionalDriverDrivingLicenseIssuedAt': trimOrNull(additionalDriverDrivingLicenseIssuedAt),
      'additionalDriverPassportNumber': trimOrNull(additionalDriverPassportNumber),
    };
  }
}
