import 'package:dio/dio.dart';

import '../models/expense_record_model.dart';
import '../models/income_record_model.dart';

class FinancialRepository {
  final Dio dio;
  FinancialRepository(this.dio);

  Future<List<IncomeRecordModel>> getIncome() async {
    final res = await dio.get('/financial/income');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(IncomeRecordModel.fromJson).toList();
  }

  Future<List<ExpenseRecordModel>> getExpenses() async {
    final res = await dio.get('/financial/expenses');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(ExpenseRecordModel.fromJson).toList();
  }
}
