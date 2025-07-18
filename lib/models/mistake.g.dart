// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mistake.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MistakeAdapter extends TypeAdapter<Mistake> {
  @override
  final int typeId = 0;

  @override
  Mistake read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mistake(
      question: fields[0] as String,
      userAnswer: fields[1] as String,
      correctAnswer: fields[2] as String,
      timestamp: fields[3] as DateTime,
      rationale: fields[4] as String,
      userAnswerLabel: fields[5] as String,
      correctAnswerLabel: fields[6] as String,
      difficulty: fields[7] as String,
      category: fields[8] as String,
      subject: fields[9] as String,
      answerOptions: (fields[10] as List).cast<MistakeAnswerOption>(),
    );
  }

  @override
  void write(BinaryWriter writer, Mistake obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.userAnswer)
      ..writeByte(2)
      ..write(obj.correctAnswer)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.rationale)
      ..writeByte(5)
      ..write(obj.userAnswerLabel)
      ..writeByte(6)
      ..write(obj.correctAnswerLabel)
      ..writeByte(7)
      ..write(obj.difficulty)
      ..writeByte(8)
      ..write(obj.category)
      ..writeByte(9)
      ..write(obj.subject)
      ..writeByte(10)
      ..write(obj.answerOptions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MistakeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MistakeAnswerOptionAdapter extends TypeAdapter<MistakeAnswerOption> {
  @override
  final int typeId = 1;

  @override
  MistakeAnswerOption read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MistakeAnswerOption(
      label: fields[0] as String,
      content: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MistakeAnswerOption obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.label)
      ..writeByte(1)
      ..write(obj.content);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MistakeAnswerOptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
