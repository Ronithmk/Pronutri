import 'package:hive/hive.dart';
part 'water_log.g.dart';

@HiveType(typeId: 1)
class WaterLog extends HiveObject {
  @HiveField(0) late double amount;
  @HiveField(1) late DateTime loggedAt;
  @HiveField(2) late String userId;

  WaterLog({required this.amount, required this.loggedAt, required this.userId});
}
