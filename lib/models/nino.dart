import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un niño estudiante
class Nino {
  final String id;
  final String nombre;
  final String grupoId;

  Nino({
    required this.id,
    required this.nombre,
    required this.grupoId,
  });

  /// Crea un Nino desde un documento de Firestore
  factory Nino.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Nino(
      id: doc.id,
      nombre: data['nombre'] as String,
      grupoId: data['grupoId'] as String,
    );
  }

  /// Convierte el Nino a un Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'grupoId': grupoId,
    };
  }

  /// Crea un Nino desde un Map (útil para fromFirestore manual)
  factory Nino.fromMap(Map<String, dynamic> map, String id) {
    return Nino(
      id: id,
      nombre: map['nombre'] as String,
      grupoId: map['grupoId'] as String,
    );
  }

  /// Crea una copia del Nino con algunos campos modificados
  Nino copyWith({
    String? id,
    String? nombre,
    String? grupoId,
  }) {
    return Nino(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      grupoId: grupoId ?? this.grupoId,
    );
  }

  @override
  String toString() {
    return 'Nino(id: $id, nombre: $nombre, grupoId: $grupoId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Nino &&
        other.id == id &&
        other.nombre == nombre &&
        other.grupoId == grupoId;
  }

  @override
  int get hashCode => id.hashCode ^ nombre.hashCode ^ grupoId.hashCode;
}