import 'package:flutter_test/flutter_test.dart';
import 'package:payment_control/models/abono.dart';
import 'package:payment_control/services/calculo_service.dart';

Abono _abono(int mes, num monto) => Abono(
  id: 'a$mes-$monto',
  ninoId: 'nino-1',
  anio: 2026,
  mes: mes,
  montoAbonado: monto,
  fechaAbono: DateTime(2026, mes, 5),
);

void main() {
  const valorCobro = 50000;
  final fechaIngreso = DateTime(2026, 3, 15); // ingresa en marzo

  // Marzo pagado, abril parcial, mayo pagado en dos abonos, resto sin pagar
  final resultados = CalculoService.calcularResultadosPorMes(
    abonos: [
      _abono(3, 50000),
      _abono(4, 20000),
      _abono(5, 30000),
      _abono(5, 20000),
    ],
    valorCobro: valorCobro,
    anio: 2026,
    fechaIngreso: fechaIngreso,
  );

  ResultadoMes mes(int m) => resultados.firstWhere((r) => r.mes == m);

  group('CalculoService.calcularResultadosPorMes', () {
    test('genera un resultado por cada mes del año', () {
      expect(resultados.length, 12);
    });

    test('los meses anteriores al ingreso no aplican y no generan deuda', () {
      expect(mes(1).estado, 'no_aplica');
      expect(mes(2).estado, 'no_aplica');
      expect(mes(2).saldoPendienteDelMes, 0);
    });

    test('el mes de ingreso sí aplica completo (no se prorratea)', () {
      expect(mes(3).estado, 'pagado');
      expect(mes(3).saldoPendienteDelMes, 0);
    });

    test('un abono menor al valor queda como abono parcial', () {
      expect(mes(4).estado, 'abono_parcial');
      expect(mes(4).saldoPendienteDelMes, 30000);
    });

    test('varios abonos del mismo mes se suman', () {
      expect(mes(5).montoAbonadoDelMes, 50000);
      expect(mes(5).estado, 'pagado');
    });

    test('un mes sin abonos queda pendiente por el valor completo', () {
      expect(mes(6).estado, 'pendiente');
      expect(mes(6).saldoPendienteDelMes, valorCobro);
    });
  });

  group('CalculoService deudas', () {
    test('la deuda visible solo cuenta meses vencidos hasta la fecha', () {
      final deuda = CalculoService.calcularDeudaVisibleActual(
        resultadosPorMes: resultados,
        anio: 2026,
        fechaReferencia: DateTime(2026, 6, 10),
      );
      // abril (30.000) + junio (50.000)
      expect(deuda, 80000);
    });

    test('la deuda total anual incluye los meses futuros', () {
      // abril (30.000) + junio a diciembre (7 x 50.000)
      expect(CalculoService.calcularDeudaTotalAnual(resultados), 380000);
    });
  });

  group('CalculoService utilidades', () {
    test('obtenerNombreMes devuelve el nombre en español', () {
      expect(CalculoService.obtenerNombreMes(1), 'Enero');
      expect(CalculoService.obtenerNombreMes(12), 'Diciembre');
      expect(CalculoService.obtenerNombreMes(13), 'Mes inválido');
    });
  });
}