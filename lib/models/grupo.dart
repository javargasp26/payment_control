import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un grupo de estudiantes de música
class Grupo {
  final String id;
  final String nombre;
  final num valorCobro;

  Grupo({
    required this.id,
    required this.nombre,
    required this.valorCobro,
  });

  /// Crea un Grupo desde un documento de Firestore
  factory Grupo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Grupo(
      id: doc.id,
      nombre: data['nombre'] as String,
      valorCobro: data['valorCobro'] as num,
    );
  }

  /// Convierte el Grupo a un Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'valorCobro': valorCobro,
    };
  }

  /// Crea un Grupo desde un Map (útil para fromFirestore manual)
  factory Grupo.fromMap(Map<String, dynamic> map, String id) {
    return Grupo(
      id: id,
      nombre: map['nombre'] as String,
      valorCobro: map['valorCobro'] as num,
    );
  }

  /// Crea una copia del Grupo con algunos campos modificados
  Grupo copyWith({
    String? id,
    String? nombre,
    num? valorCobro,
  }) {
    return Grupo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      valorCobro: valorCobro ?? this.valorCobro,
    );
  }

  @override
  String toString() {
    return 'Grupo(id: $id, nombre: $nombre, valorCobro: $valorCobro)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Grupo &&
        other.id == id &&
        other.nombre == nombre &&
        other.valorCobro == valorCobro;
  }

  @override
  int get hashCode => id.hashCode ^ nombre.hashCode ^ valorCobro.hashCode;
}