import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un niño estudiante
class Nino {
  final String id;
  final String nombre;
  final String? segundoNombre;
  final String primerApellido;
  final String? segundoApellido;
  final String? telefonoContacto;
  final String nombreAcudiente;
  final String telefonoAcudiente;
  final String grupoId;
  final DateTime fechaIngreso;

  Nino({
    required this.id,
    required this.nombre,
    this.segundoNombre,
    required this.primerApellido,
    this.segundoApellido,
    this.telefonoContacto,
    required this.nombreAcudiente,
    required this.telefonoAcudiente,
    required this.grupoId,
    required this.fechaIngreso,
  });

  /// Nombre completo del niño, concatenando nombre, segundo nombre (si existe),
  /// primer apellido y segundo apellido (si existe), sin espacios dobles.
  String get nombreCompleto {
    return [
      nombre,
      if (segundoNombre != null && segundoNombre!.trim().isNotEmpty)
        segundoNombre!.trim(),
      primerApellido,
      if (segundoApellido != null && segundoApellido!.trim().isNotEmpty)
        segundoApellido!.trim(),
    ].where((parte) => parte.trim().isNotEmpty).join(' ');
  }

  /// Crea un Nino desde un documento de Firestore
  factory Nino.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Nino.fromMap(data, doc.id);
  }

  /// Convierte el Nino a un Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'segundoNombre': segundoNombre,
      'primerApellido': primerApellido,
      'segundoApellido': segundoApellido,
      'telefonoContacto': telefonoContacto,
      'nombreAcudiente': nombreAcudiente,
      'telefonoAcudiente': telefonoAcudiente,
      'grupoId': grupoId,
      'fechaIngreso': Timestamp.fromDate(fechaIngreso),
    };
  }

  /// Crea un Nino desde un Map (útil para fromFirestore manual)
  ///
  /// Los niños creados antes de ampliar este modelo solo tienen los campos
  /// "nombre" y "grupoId" en Firestore, por lo que los campos nuevos
  /// obligatorios (primerApellido, nombreAcudiente, telefonoAcudiente) se
  /// leen de forma segura con un valor por defecto de cadena vacía si aún
  /// no existen en el documento.
  factory Nino.fromMap(Map<String, dynamic> map, String id) {
    // NOTA: los niños creados antes de agregar "fechaIngreso" no tienen este
    // campo en Firestore. Para no romper la carga se usa por defecto el 1 de
    // enero del año actual, pero este valor es un placeholder: para estos
    // niños hay que CORREGIR MANUALMENTE la fecha de ingreso real editando
    // al niño desde el formulario.
    final fechaIngresoTimestamp = map['fechaIngreso'] as Timestamp?;
    final fechaIngreso = fechaIngresoTimestamp?.toDate() ??
        DateTime(DateTime.now().year, 1, 1);

    return Nino(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      segundoNombre: map['segundoNombre'] as String?,
      primerApellido: map['primerApellido'] as String? ?? '',
      segundoApellido: map['segundoApellido'] as String?,
      telefonoContacto: map['telefonoContacto'] as String?,
      nombreAcudiente: map['nombreAcudiente'] as String? ?? '',
      telefonoAcudiente: map['telefonoAcudiente'] as String? ?? '',
      grupoId: map['grupoId'] as String? ?? '',
      fechaIngreso: fechaIngreso,
    );
  }

  /// Crea una copia del Nino con algunos campos modificados
  Nino copyWith({
    String? id,
    String? nombre,
    String? segundoNombre,
    String? primerApellido,
    String? segundoApellido,
    String? telefonoContacto,
    String? nombreAcudiente,
    String? telefonoAcudiente,
    String? grupoId,
    DateTime? fechaIngreso,
  }) {
    return Nino(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      segundoNombre: segundoNombre ?? this.segundoNombre,
      primerApellido: primerApellido ?? this.primerApellido,
      segundoApellido: segundoApellido ?? this.segundoApellido,
      telefonoContacto: telefonoContacto ?? this.telefonoContacto,
      nombreAcudiente: nombreAcudiente ?? this.nombreAcudiente,
      telefonoAcudiente: telefonoAcudiente ?? this.telefonoAcudiente,
      grupoId: grupoId ?? this.grupoId,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
    );
  }

  @override
  String toString() {
    return 'Nino(id: $id, nombreCompleto: $nombreCompleto, grupoId: $grupoId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Nino &&
        other.id == id &&
        other.nombre == nombre &&
        other.segundoNombre == segundoNombre &&
        other.primerApellido == primerApellido &&
        other.segundoApellido == segundoApellido &&
        other.telefonoContacto == telefonoContacto &&
        other.nombreAcudiente == nombreAcudiente &&
        other.telefonoAcudiente == telefonoAcudiente &&
        other.grupoId == grupoId &&
        other.fechaIngreso == fechaIngreso;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      nombre.hashCode ^
      segundoNombre.hashCode ^
      primerApellido.hashCode ^
      segundoApellido.hashCode ^
      telefonoContacto.hashCode ^
      nombreAcudiente.hashCode ^
      telefonoAcudiente.hashCode ^
      grupoId.hashCode ^
      fechaIngreso.hashCode;
}
