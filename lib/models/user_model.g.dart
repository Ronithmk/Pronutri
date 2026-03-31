// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'user_model.dart';

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override final int typeId = 2;

  @override
  UserModel read(BinaryReader reader) {
    final n = reader.readByte();
    final f = <int, dynamic>{for (int i = 0; i < n; i++) reader.readByte(): reader.read()};
    return UserModel(
      id: f[0] as String, name: f[1] as String, email: f[2] as String,
      password: f[3] as String, weight: f[4] as double, height: f[5] as double,
      age: f[6] as int, gender: f[7] as String, goal: f[8] as String,
      activityLevel: f[9] as String, createdAt: f[10] as DateTime,
      profileImagePath: f[11] as String?, targetWeight: f[12] as double,
      emailVerified: f[13] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer..writeByte(14)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.email)
      ..writeByte(3)..write(obj.password)
      ..writeByte(4)..write(obj.weight)
      ..writeByte(5)..write(obj.height)
      ..writeByte(6)..write(obj.age)
      ..writeByte(7)..write(obj.gender)
      ..writeByte(8)..write(obj.goal)
      ..writeByte(9)..write(obj.activityLevel)
      ..writeByte(10)..write(obj.createdAt)
      ..writeByte(11)..write(obj.profileImagePath)
      ..writeByte(12)..write(obj.targetWeight)
      ..writeByte(13)..write(obj.emailVerified);
  }

  @override int get hashCode => typeId.hashCode;
  @override bool operator ==(Object other) => identical(this, other) || other is UserModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
