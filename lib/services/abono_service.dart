import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/abono.dart';
import '../models/nino.dart';
import '../models/grupo.dart';
import 'calculo_service.dart';

/// Resultado de la distribución de un pago
class ResultadoDistribucionPago {
  final List<Map<String, dynamic>> abonosCreados;
  final String mensajeConfirmacion;
  final num montoTotalDistribuido;

  ResultadoDistribucionPago({
    required this.abonosCreados,
    required this.mensajeConfirmacion,
    required this.montoTotalDistribuido,
  });
}

/// Servicio para gestionar abonos en Firestore
class AbonoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'abonos';

  /// Crea un nuevo abono en Firestore
  Future<Abono> crearAbono({
    required String ninoId,
    required int anio,
    required int mes,
    required num montoAbonado,
    DateTime? fechaAbono,
  }) async {
    final fecha = fechaAbono ?? DateTime.now();

    final docRef = await _firestore.collection(_collection).add({
      'ninoId': ninoId,
      'anio': anio,
      'mes': mes,
      'montoAbonado': montoAbonado,
      'fechaAbono': Timestamp.fromDate(fecha),
    });

    final doc = await docRef.get();
    return Abono.fromFirestore(doc);
  }

  /// Obtiene todos los abonos de un niño en un año específico en tiempo real
  Stream<List<Abono>> obtenerAbonosPorNinoYAnioStream({
    required String ninoId,
    required int anio,
  }) {
    return _firestore
        .collection(_collection)
        .where('ninoId', isEqualTo: ninoId)
        .where('anio', isEqualTo: anio)
        .orderBy('fechaAbono', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Abono.fromFirestore(doc)).toList();
    });
  }

  /// Obtiene todos los abonos de un niño en un año específico (puntual)
  Future<List<Abono>> obtenerAbonosPorNinoYAnio({
    required String ninoId,
    required int anio,
  }) async {
    final snapshot = await _firestore
        .collection(_collection)
        .where('ninoId', isEqualTo: ninoId)
        .where('anio', isEqualTo: anio)
        .orderBy('fechaAbono', descending: true)
        .get();

    return snapshot.docs.map((doc) => Abono.fromFirestore(doc)).toList();
  }

  /// Obtiene todos los abonos de un niño en tiempo real
  Stream<List<Abono>> obtenerAbonosPorNinoStream(String ninoId) {
    return _firestore
        .collection(_collection)
        .where('ninoId', isEqualTo: ninoId)
        .orderBy('fechaAbono', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Abono.fromFirestore(doc)).toList();
    });
  }

  /// Obtiene un abono específico por ID
  Future<Abono?> obtenerAbonoPorId(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Abono.fromFirestore(doc);
  }

  /// Obtiene un abono específico por ID en tiempo real
  Stream<Abono?> obtenerAbonoPorIdStream(String id) {
    return _firestore
        .collection(_collection)
        .doc(id)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Abono.fromFirestore(doc);
    });
  }

  /// Actualiza un abono existente
  Future<void> actualizarAbono({
    required String id,
    String? ninoId,
    int? anio,
    int? mes,
    num? montoAbonado,
    DateTime? fechaAbono,
  }) async {
    final Map<String, dynamic> data = {};

    if (ninoId != null) data['ninoId'] = ninoId;
    if (anio != null) data['anio'] = anio;
    if (mes != null) data['mes'] = mes;
    if (montoAbonado != null) data['montoAbonado'] = montoAbonado;
    if (fechaAbono != null) data['fechaAbono'] = Timestamp.fromDate(fechaAbono);

    if (data.isNotEmpty) {
      await _firestore.collection(_collection).doc(id).update(data);
    }
  }

  /// Elimina un abono por ID
  Future<void> eliminarAbono(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Obtiene el total abonado por un niño en un año específico
  Stream<num> obtenerTotalAbonadoPorNinoYAnioStream({
    required String ninoId,
    required int anio,
  }) {
    return _firestore
        .collection(_collection)
        .where('ninoId', isEqualTo: ninoId)
        .where('anio', isEqualTo: anio)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.fold<num>(
        0,
        (total, doc) {
          final data = doc.data();
          return total + (data['montoAbonado'] as num);
        },
      );
    });
  }

  /// Registra un abono con distribución automática a meses pendientes
  /// Si el monto supera el saldo pendiente del mes seleccionado, el excedente
  /// se aplica al mes pendiente más antiguo, y así sucesivamente.
  Future<ResultadoDistribucionPago> registrarAbonoConDistribucion({
    required String ninoId,
    required Grupo grupo,
    required int anio,
    required int mesSeleccionado,
    required num montoTotal,
    DateTime? fechaAbono,
  }) async {
    final fecha = fechaAbono ?? DateTime.now();
    final batch = _firestore.batch();
    
    // Obtener abonos existentes del niño en el año
    final abonosExistentes = await obtenerAbonosPorNinoYAnio(
      ninoId: ninoId,
      anio: anio,
    );
    
    // Calcular saldos pendientes de cada mes
    final resultadoAnual = CalculoService.calcularResultadoAnual(
      nino: Nino(id: ninoId, nombre: '', grupoId: grupo.id),
      grupo: grupo,
      abonos: abonosExistentes,
      anio: anio,
    );
    
    // Obtener nombres de meses para el mensaje
    const nombresMeses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    // Lista para guardar los abonos creados
    final List<Map<String, dynamic>> abonosCreados = [];
    final List<String> mesesCubiertos = [];
    
    num montoRestante = montoTotal;
    
    // Construir la secuencia de meses a cubrir en el orden correcto:
    // 1. Meses ANTERIORES al mesSeleccionado con saldo pendiente > 0 (en orden cronológico)
    // 2. El mesSeleccionado mismo (si tiene saldo pendiente > 0)
    // 3. Meses POSTERIORES al mesSeleccionado (en orden cronológico, como pago anticipado)
    final List<int> secuenciaMeses = [];
    
    // Paso 1: Agregar meses anteriores con saldo pendiente (en orden cronológico)
    for (int mes = 1; mes < mesSeleccionado; mes++) {
      final resultado = resultadoAnual.obtenerResultadoMes(mes);
      if (resultado != null && resultado.saldoPendienteDelMes > 0) {
        secuenciaMeses.add(mes);
      }
    }
    
    // Paso 2: Agregar el mes seleccionado si tiene saldo pendiente
    final resultadoMesSeleccionado = resultadoAnual.obtenerResultadoMes(mesSeleccionado);
    if (resultadoMesSeleccionado != null && resultadoMesSeleccionado.saldoPendienteDelMes > 0) {
      secuenciaMeses.add(mesSeleccionado);
    }
    
    // Paso 3: Agregar meses posteriores (en orden cronológico, como pago anticipado)
    for (int mes = mesSeleccionado + 1; mes <= 12; mes++) {
      secuenciaMeses.add(mes);
    }
    
    // Recorrer la secuencia aplicando el monto mes por mes
    for (int mes in secuenciaMeses) {
      if (montoRestante <= 0) break;
      
      final resultado = resultadoAnual.obtenerResultadoMes(mes);
      if (resultado == null) continue;
      
      final saldoPendiente = resultado.saldoPendienteDelMes;
      
      // Determinar el monto a aplicar a este mes
      num montoAplicar;
      if (saldoPendiente > 0) {
        // Mes con deuda: aplicar hasta cubrir el saldo pendiente
        montoAplicar = montoRestante < saldoPendiente 
            ? montoRestante 
            : saldoPendiente;
      } else {
        // Mes sin deuda: aplicar todo el remanente como abono anticipado
        montoAplicar = montoRestante;
      }
      
      // Crear el abono para este mes
      final docRef = _firestore.collection(_collection).doc();
      batch.set(docRef, {
        'ninoId': ninoId,
        'anio': anio,
        'mes': mes,
        'montoAbonado': montoAplicar,
        'fechaAbono': Timestamp.fromDate(fecha),
      });
      
      abonosCreados.add({
        'mes': mes,
        'monto': montoAplicar,
        'nombreMes': nombresMeses[mes - 1],
      });
      
      mesesCubiertos.add('${nombresMeses[mes - 1]} (\$${montoAplicar.toStringAsFixed(0)})');
      
      montoRestante -= montoAplicar;
      
      // Si ya no queda monto, terminamos
      if (montoRestante <= 0) break;
    }
    
    // Ejecutar el batch de forma atómica
    await batch.commit();
    
    // Construir mensaje de confirmación
    String mensajeConfirmacion;
    if (mesesCubiertos.length == 1) {
      mensajeConfirmacion = 'Pago registrado: \$${montoTotal.toStringAsFixed(0)} aplicados a ${mesesCubiertos[0]}';
    } else {
      mensajeConfirmacion = 'Pago registrado: ${mesesCubiertos.join(', ')}';
    }
    
    return ResultadoDistribucionPago(
      abonosCreados: abonosCreados,
      mensajeConfirmacion: mensajeConfirmacion,
      montoTotalDistribuido: montoTotal,
    );
  }
}