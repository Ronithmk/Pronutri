// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'meal_log.dart';

class MealLogAdapter extends TypeAdapter<MealLog> {
  @override final int typeId = 0;

  @override
  MealLog read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return MealLog(
      foodName: f[0] as String, emoji: f[1] as String,
      calories: f[2] as double, protein: f[3] as double,
      carbs: f[4] as double, fat: f[5] as double,
      loggedAt: f[6] as DateTime, mealType: f[7] as String,
      quantity: f[8] as double, serving: f[9] as String,
      userId: f[10] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, MealLog obj) {
    writer..writeByte(11)
      ..writeByte(0)..write(obj.foodName)
      ..writeByte(1)..write(obj.emoji)
      ..writeByte(2)..write(obj.calories)
      ..writeByte(3)..write(obj.protein)
      ..writeByte(4)..write(obj.carbs)
      ..writeByte(5)..write(obj.fat)
      ..writeByte(6)..write(obj.loggedAt)
      ..writeByte(7)..write(obj.mealType)
      ..writeByte(8)..write(obj.quantity)
      ..writeByte(9)..write(obj.serving)
      ..writeByte(10)..write(obj.userId);
  }

  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object other) => identical(this, other) || other is MealLogAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
