import '../models/abono.dart';
import '../models/grupo.dart';
import '../models/nino.dart';

/// Resultado del cálculo de un mes específico
class ResultadoMes {
  final int mes;
  final num montoAbonadoDelMes;
  final num saldoPendienteDelMes;
  final String estado; // "pagado", "pendiente", "abono_parcial", "no_aplica"

  ResultadoMes({
    required this.mes,
    required this.montoAbonadoDelMes,
    required this.saldoPendienteDelMes,
    required this.estado,
  });

  @override
  String toString() {
    return 'ResultadoMes(mes: $mes, montoAbonado: $montoAbonadoDelMes, saldoPendiente: $saldoPendienteDelMes, estado: $estado)';
  }
}

/// Resultado del cálculo anual de un niño
class ResultadoAnual {
  final String ninoId;
  final String ninoNombre;
  final int anio;
  final num valorCobro;
  final List<ResultadoMes> resultadosPorMes;
  final num deudaTotalAnual;
  final num deudaVisibleActual;

  ResultadoAnual({
    required this.ninoId,
    required this.ninoNombre,
    required this.anio,
    required this.valorCobro,
    required this.resultadosPorMes,
    required this.deudaTotalAnual,
    required this.deudaVisibleActual,
  });

  /// Obtiene el resultado de un mes específico (1-12)
  ResultadoMes? obtenerResultadoMes(int mes) {
    if (mes < 1 || mes > 12) return null;
    return resultadosPorMes.firstWhere(
      (r) => r.mes == mes,
      orElse: () => ResultadoMes(
        mes: mes,
        montoAbonadoDelMes: 0,
        saldoPendienteDelMes: valorCobro,
        estado: 'pendiente',
      ),
    );
  }

  @override
  String toString() {
    return 'ResultadoAnual(nino: $ninoNombre, anio: $anio, deudaTotal: $deudaTotalAnual)';
  }
}

/// Servicio de cálculos para la lógica de negocio de pagos
class CalculoService {
  /// Calcula el estado de un mes basado en el monto abonado y el valor de cobro
  static String _calcularEstado(num montoAbonado, num valorCobro) {
    if (montoAbonado >= valorCobro) {
      return 'pagado';
    } else if (montoAbonado == 0) {
      return 'pendiente';
    } else {
      return 'abono_parcial';
    }
  }

  /// Determina si un mes (año, mes) es anterior a la fecha de ingreso del
  /// niño. La comparación es por año y mes calendario, no por día: el mes
  /// completo de ingreso ya se considera aplicable (no se prorratea).
  static bool _esAnteriorAIngreso({
    required int anio,
    required int mes,
    required DateTime fechaIngreso,
  }) {
    if (anio != fechaIngreso.year) {
      return anio < fechaIngreso.year;
    }
    return mes < fechaIngreso.month;
  }

  /// Calcula los resultados por mes para un niño en un año específico
  static List<ResultadoMes> calcularResultadosPorMes({
    required List<Abono> abonos,
    required num valorCobro,
    required int anio,
    required DateTime fechaIngreso,
  }) {
    // Inicializar todos los meses con 0 abonado
    final Map<int, num> abonosPorMes = {};
    for (int mes = 1; mes <= 12; mes++) {
      abonosPorMes[mes] = 0;
    }

    // Sumar los abonos por mes
    for (final abono in abonos) {
      final mes = abono.mes;
      abonosPorMes[mes] = (abonosPorMes[mes] ?? 0) + abono.montoAbonado;
    }

    // Crear resultados por mes
    final resultados = <ResultadoMes>[];
    for (int mes = 1; mes <= 12; mes++) {
      final montoAbonado = abonosPorMes[mes] ?? 0;

      // Los meses anteriores a la fecha de ingreso del niño no son deuda:
      // no aplican, y su saldo pendiente se fuerza a 0 para que no sume a
      // la deuda total anual.
      if (_esAnteriorAIngreso(anio: anio, mes: mes, fechaIngreso: fechaIngreso)) {
        resultados.add(ResultadoMes(
          mes: mes,
          montoAbonadoDelMes: montoAbonado,
          saldoPendienteDelMes: 0,
          estado: 'no_aplica',
        ));
        continue;
      }

      final saldoPendiente = valorCobro - montoAbonado;
      final estado = _calcularEstado(montoAbonado, valorCobro);

      resultados.add(ResultadoMes(
        mes: mes,
        montoAbonadoDelMes: montoAbonado,
        saldoPendienteDelMes: saldoPendiente,
        estado: estado,
      ));
    }

    return resultados;
  }

  /// Calcula la deuda total anual de un niño, sumando el saldo pendiente de
  /// los 12 meses del año (incluye meses futuros que aún no han "vencido").
  /// Se conserva para otros usos internos; para mostrar la deuda visible al
  /// usuario usa [calcularDeudaVisibleActual].
  static num calcularDeudaTotalAnual(List<ResultadoMes> resultadosPorMes) {
    return resultadosPorMes.fold<num>(
      0,
      (suma, resultado) {
        // Solo sumar saldos pendientes positivos (deuda real)
        if (resultado.saldoPendienteDelMes > 0) {
          return suma + resultado.saldoPendienteDelMes;
        }
        return suma;
      },
    );
  }

  /// Calcula la deuda "visible" a la fecha actual: solo suma el saldo
  /// pendiente de los meses ya "vencidos" (desde la fechaIngreso, ya
  /// reflejada en el estado "no_aplica", hasta el mes actual inclusive).
  ///
  /// Los meses futuros (mayores al mes actual, cuando `anio` es el año en
  /// curso) NO se cuentan aunque tengan saldo pendiente, ni tampoco si ya
  /// tienen un abono anticipado registrado: simplemente no han llegado
  /// todavía, así que no suman ni restan a este número.
  static num calcularDeudaVisibleActual({
    required List<ResultadoMes> resultadosPorMes,
    required int anio,
    DateTime? fechaReferencia,
  }) {
    final ahora = fechaReferencia ?? DateTime.now();

    int mesLimite;
    if (anio < ahora.year) {
      mesLimite = 12; // Año ya terminado: todos sus meses ya "vencieron"
    } else if (anio > ahora.year) {
      mesLimite = 0; // Año futuro: ningún mes ha llegado todavía
    } else {
      mesLimite = ahora.month;
    }

    return resultadosPorMes.fold<num>(0, (suma, resultado) {
      if (resultado.estado == 'no_aplica') return suma;
      if (resultado.mes > mesLimite) return suma;
      if (resultado.saldoPendienteDelMes > 0) {
        return suma + resultado.saldoPendienteDelMes;
      }
      return suma;
    });
  }

  /// Calcula el resultado anual completo de un niño
  static ResultadoAnual calcularResultadoAnual({
    required Nino nino,
    required Grupo grupo,
    required List<Abono> abonos,
    required int anio,
  }) {
    final resultadosPorMes = calcularResultadosPorMes(
      abonos: abonos,
      valorCobro: grupo.valorCobro,
      anio: anio,
      fechaIngreso: nino.fechaIngreso,
    );

    final deudaTotalAnual = calcularDeudaTotalAnual(resultadosPorMes);
    final deudaVisibleActual = calcularDeudaVisibleActual(
      resultadosPorMes: resultadosPorMes,
      anio: anio,
    );

    return ResultadoAnual(
      ninoId: nino.id,
      ninoNombre: nino.nombreCompleto,
      anio: anio,
      valorCobro: grupo.valorCobro,
      resultadosPorMes: resultadosPorMes,
      deudaTotalAnual: deudaTotalAnual,
      deudaVisibleActual: deudaVisibleActual,
    );
  }

  /// Calcula los resultados anuales para múltiples niños
  static List<ResultadoAnual> calcularResultadosAnuales({
    required List<Nino> ninos,
    required Map<String, Grupo> gruposPorId,
    required Map<String, List<Abono>> abonosPorNinoId,
    required int anio,
  }) {
    final resultados = <ResultadoAnual>[];

    for (final nino in ninos) {
      final grupo = gruposPorId[nino.grupoId];
      if (grupo == null) continue; // Saltar si no se encuentra el grupo

      final abonos = abonosPorNinoId[nino.id] ?? [];

      final resultadoAnual = calcularResultadoAnual(
        nino: nino,
        grupo: grupo,
        abonos: abonos,
        anio: anio,
      );

      resultados.add(resultadoAnual);
    }

    // Ordenar por nombre del niño
    resultados.sort((a, b) => a.ninoNombre.compareTo(b.ninoNombre));

    return resultados;
  }

  /// Obtiene el nombre del mes en español
  static String obtenerNombreMes(int mes) {
    const nombres = [
      '', // índice 0 no usado
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    if (mes < 1 || mes > 12) return 'Mes inválido';
    return nombres[mes];
  }

  /// Obtiene el color asociado al estado del pago
  static String obtenerColorEstado(String estado) {
    switch (estado) {
      case 'pagado':
        return 'green';
      case 'pendiente':
        return 'red';
      case 'abono_parcial':
        return 'orange';
      case 'no_aplica':
        return 'gray';
      default:
        return 'gray';
    }
  }
}