import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nino.dart';

/// Servicio para gestionar niños en Firestore
class NinoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ninos';

  /// Crea un nuevo niño en Firestore
  Future<Nino> crearNino({
    required String nombre,
    String? segundoNombre,
    required String primerApellido,
    String? segundoApellido,
    String? telefonoContacto,
    required String nombreAcudiente,
    required String telefonoAcudiente,
    required String grupoId,
    required DateTime fechaIngreso,
  }) async {
    final docRef = await _firestore.collection(_collection).add({
      'nombre': nombre,
      'segundoNombre': segundoNombre,
      'primerApellido': primerApellido,
      'segundoApellido': segundoApellido,
      'telefonoContacto': telefonoContacto,
      'nombreAcudiente': nombreAcudiente,
      'telefonoAcudiente': telefonoAcudiente,
      'grupoId': grupoId,
      'fechaIngreso': Timestamp.fromDate(fechaIngreso),
    });

    final doc = await docRef.get();
    return Nino.fromFirestore(doc);
  }

  /// Obtiene todos los niños en tiempo real usando Stream
  Stream<List<Nino>> obtenerNinosStream() {
    return _firestore
        .collection(_collection)
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Nino.fromFirestore(doc)).toList();
    });
  }

  /// Obtiene todos los niños de un grupo específico en tiempo real
  Stream<List<Nino>> obtenerNinosPorGrupoStream(String grupoId) {
    return _firestore
        .collection(_collection)
        .where('grupoId', isEqualTo: grupoId)
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Nino.fromFirestore(doc)).toList();
    });
  }

  /// Obtiene un niño específico por ID
  Future<Nino?> obtenerNinoPorId(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Nino.fromFirestore(doc);
  }

  /// Obtiene un niño específico por ID en tiempo real
  Stream<Nino?> obtenerNinoPorIdStream(String id) {
    return _firestore
        .collection(_collection)
        .doc(id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Nino.fromFirestore(doc);
    });
  }

  /// Actualiza un niño existente con los nuevos valores del formulario de
  /// edición. Si `grupoId` cambia, solo se reasigna el niño al nuevo grupo:
  /// los abonos ya registrados quedan asociados por `ninoId` (no por grupo),
  /// por lo que su histórico no se ve afectado.
  Future<void> actualizarNino({
    required String id,
    required String nombre,
    String? segundoNombre,
    required String primerApellido,
    String? segundoApellido,
    String? telefonoContacto,
    required String nombreAcudiente,
    required String telefonoAcudiente,
    required String grupoId,
    required DateTime fechaIngreso,
  }) async {
    await _firestore.collection(_collection).doc(id).update({
      'nombre': nombre,
      'segundoNombre': segundoNombre,
      'primerApellido': primerApellido,
      'segundoApellido': segundoApellido,
      'telefonoContacto': telefonoContacto,
      'nombreAcudiente': nombreAcudiente,
      'telefonoAcudiente': telefonoAcudiente,
      'grupoId': grupoId,
      'fechaIngreso': Timestamp.fromDate(fechaIngreso),
    });
  }

  /// Elimina un niño y todos sus abonos asociados de forma atómica: se usa
  /// un WriteBatch para que, si algo falla, no se borre nada (ni el niño ni
  /// sus abonos quedan a medio eliminar).
  Future<void> eliminarNino(String id) async {
    final batch = _firestore.batch();

    final abonosSnapshot = await _firestore
        .collection('abonos')
        .where('ninoId', isEqualTo: id)
        .get();
    for (final doc in abonosSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_firestore.collection(_collection).doc(id));

    await batch.commit();
  }

  /// Obtiene el conteo de niños en tiempo real
  Stream<int> obtenerConteoNinosStream() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Obtiene el conteo de niños de un grupo específico en tiempo real
  Stream<int> obtenerConteoNinosPorGrupoStream(String grupoId) {
    return _firestore
        .collection(_collection)
        .where('grupoId', isEqualTo: grupoId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}