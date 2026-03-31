// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'water_log.dart';

class WaterLogAdapter extends TypeAdapter<WaterLog> {
  @override final int typeId = 1;

  @override
  WaterLog read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return WaterLog(amount: f[0] as double, loggedAt: f[1] as DateTime, userId: f[2] as String? ?? '');
  }

  @override
  void write(BinaryWriter writer, WaterLog obj) {
    writer..writeByte(3)..writeByte(0)..write(obj.amount)..writeByte(1)..write(obj.loggedAt)..writeByte(2)..write(obj.userId);
  }

  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object other) => identical(this, other) || other is WaterLogAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
