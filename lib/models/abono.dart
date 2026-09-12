import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un abono de pago
class Abono {
  final String id;
  final String ninoId;
  final int anio;
  final int mes; // 1-12
  final num montoAbonado;
  final DateTime fechaAbono;

  Abono({
    required this.id,
    required this.ninoId,
    required this.anio,
    required this.mes,
    required this.montoAbonado,
    required this.fechaAbono,
  });

  /// Crea un Abono desde un documento de Firestore
  factory Abono.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Abono(
      id: doc.id,
      ninoId: data['ninoId'] as String,
      anio: data['anio'] as int,
      mes: data['mes'] as int,
      montoAbonado: data['montoAbonado'] as num,
      fechaAbono: (data['fechaAbono'] as Timestamp).toDate(),
    );
  }

  /// Convierte el Abono a un Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'ninoId': ninoId,
      'anio': anio,
      'mes': mes,
      'montoAbonado': montoAbonado,
      'fechaAbono': Timestamp.fromDate(fechaAbono),
    };
  }

  /// Crea un Abono desde un Map (útil para fromFirestore manual)
  factory Abono.fromMap(Map<String, dynamic> map, String id) {
    return Abono(
      id: id,
      ninoId: map['ninoId'] as String,
      anio: map['anio'] as int,
      mes: map['mes'] as int,
      montoAbonado: map['montoAbonado'] as num,
      fechaAbono: (map['fechaAbono'] as Timestamp).toDate(),
    );
  }

  /// Crea una copia del Abono con algunos campos modificados
  Abono copyWith({
    String? id,
    String? ninoId,
    int? anio,
    int? mes,
    num? montoAbonado,
    DateTime? fechaAbono,
  }) {
    return Abono(
      id: id ?? this.id,
      ninoId: ninoId ?? this.ninoId,
      anio: anio ?? this.anio,
      mes: mes ?? this.mes,
      montoAbonado: montoAbonado ?? this.montoAbonado,
      fechaAbono: fechaAbono ?? this.fechaAbono,
    );
  }

  @override
  String toString() {
    return 'Abono(id: $id, ninoId: $ninoId, anio: $anio, mes: $mes, montoAbonado: $montoAbonado, fechaAbono: $fechaAbono)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Abono &&
        other.id == id &&
        other.ninoId == ninoId &&
        other.anio == anio &&
        other.mes == mes &&
        other.montoAbonado == montoAbonado &&
        other.fechaAbono == fechaAbono;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ninoId.hashCode ^
        anio.hashCode ^
        mes.hashCode ^
        montoAbonado.hashCode ^
        fechaAbono.hashCode;
  }
}