import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grupo.dart';

/// Servicio para gestionar grupos en Firestore
class GrupoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'grupos';

  /// Crea un nuevo grupo en Firestore
  Future<Grupo> crearGrupo({
    required String nombre,
    required num valorCobro,
  }) async {
    final docRef = await _firestore.collection(_collection).add({
      'nombre': nombre,
      'valorCobro': valorCobro,
    });

    final doc = await docRef.get();
    return Grupo.fromFirestore(doc);
  }

  /// Obtiene todos los grupos en tiempo real usando Stream
  Stream<List<Grupo>> obtenerGruposStream() {
    return _firestore
        .collection(_collection)
        .orderBy('nombre')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Grupo.fromFirestore(doc)).toList();
    });
  }

  /// Obtiene un grupo específico por ID
  Future<Grupo?> obtenerGrupoPorId(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Grupo.fromFirestore(doc);
  }

  /// Obtiene un grupo específico por ID en tiempo real
  Stream<Grupo?> obtenerGrupoPorIdStream(String id) {
    return _firestore
        .collection(_collection)
        .doc(id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Grupo.fromFirestore(doc);
    });
  }

  /// Actualiza un grupo existente
  Future<void> actualizarGrupo({
    required String id,
    String? nombre,
    num? valorCobro,
  }) async {
    final Map<String, dynamic> data = {};

    if (nombre != null) data['nombre'] = nombre;
    if (valorCobro != null) data['valorCobro'] = valorCobro;

    if (data.isNotEmpty) {
      await _firestore.collection(_collection).doc(id).update(data);
    }
  }

  /// Elimina un grupo por ID
  Future<void> eliminarGrupo(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Obtiene el conteo de grupos en tiempo real
  Stream<int> obtenerConteoGruposStream() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}