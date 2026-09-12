import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/nino.dart';

/// Servicio para gestionar niños en Firestore
class NinoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'ninos';

  /// Crea un nuevo niño en Firestore
  Future<Nino> crearNino({
    required String nombre,
    required String grupoId,
  }) async {
    final docRef = await _firestore.collection(_collection).add({
      'nombre': nombre,
      'grupoId': grupoId,
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

  /// Actualiza un niño existente
  Future<void> actualizarNino({
    required String id,
    String? nombre,
    String? grupoId,
  }) async {
    final Map<String, dynamic> data = {};

    if (nombre != null) data['nombre'] = nombre;
    if (grupoId != null) data['grupoId'] = grupoId;

    if (data.isNotEmpty) {
      await _firestore.collection(_collection).doc(id).update(data);
    }
  }

  /// Elimina un niño por ID
  Future<void> eliminarNino(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
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