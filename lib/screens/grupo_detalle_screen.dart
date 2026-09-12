import 'package:flutter/material.dart';
import '../models/grupo.dart';
import '../models/nino.dart';
import '../models/abono.dart';
import '../services/grupo_service.dart';
import '../services/nino_service.dart';
import '../services/abono_service.dart';
import '../services/calculo_service.dart';

/// Pantalla de detalle de un grupo que muestra los niños y su estado de pagos
class GrupoDetalleScreen extends StatefulWidget {
  final String grupoId;
  final String grupoNombre;

  const GrupoDetalleScreen({
    super.key,
    required this.grupoId,
    required this.grupoNombre,
  });

  @override
  State<GrupoDetalleScreen> createState() => _GrupoDetalleScreenState();
}

class _GrupoDetalleScreenState extends State<GrupoDetalleScreen> {
  final GrupoService _grupoService = GrupoService();
  final NinoService _ninoService = NinoService();
  final AbonoService _abonoService = AbonoService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.grupoNombre),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildGrupoDetalle(),
    );
  }

  Widget _buildGrupoDetalle() {
    return StreamBuilder<Grupo?>(
      stream: _grupoService.obtenerGrupoPorIdStream(widget.grupoId),
      builder: (context, grupoSnapshot) {
        // Estado de carga del grupo
        if (grupoSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Cargando información del grupo...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Error al cargar el grupo
        if (grupoSnapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar el grupo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    grupoSnapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final grupo = grupoSnapshot.data;

        // Grupo no encontrado
        if (grupo == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_off,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Grupo no encontrado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Regresar'),
                  ),
                ],
              ),
            ),
          );
        }

        // Mostrar valor de cobro y lista de niños
        return Column(
          children: [
            // Valor de cobro mensual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.blue.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor mensual',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '\$${grupo.valorCobro.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Lista de niños
            Expanded(
              child: _buildNinosList(grupo),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNinosList(Grupo grupo) {
    return StreamBuilder<List<Nino>>(
      stream: _ninoService.obtenerNinosPorGrupoStream(widget.grupoId),
      builder: (context, ninosSnapshot) {
        // Estado de carga de niños
        if (ninosSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Cargando niños...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Error al cargar niños
        if (ninosSnapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error al cargar niños',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ninosSnapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final ninos = ninosSnapshot.data ?? [];

        // Sin niños
        if (ninos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.child_care,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Este grupo aún no tiene niños',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Agrégalo desde el botón + de la pantalla principal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Regresar a la pantalla principal'),
                  ),
                ],
              ),
            ),
          );
        }

        // Lista de niños con estado de pagos
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(seconds: 1));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ninos.length,
            itemBuilder: (context, index) {
              final nino = ninos[index];
              return _buildNinoCard(nino, grupo);
            },
          ),
        );
      },
    );
  }

  Widget _buildNinoCard(Nino nino, Grupo grupo) {
    final anioActual = DateTime.now().year;

    return StreamBuilder<List<Abono>>(
      stream: _abonoService.obtenerAbonosPorNinoYAnioStream(
        ninoId: nino.id,
        anio: anioActual,
      ),
      builder: (context, abonosSnapshot) {
        final abonos = abonosSnapshot.data ?? [];
        
        // Calcular resultado anual usando CalculoService
        final resultadoAnual = CalculoService.calcularResultadoAnual(
          nino: nino,
          grupo: grupo,
          abonos: abonos,
          anio: anioActual,
        );

        final deudaTotal = resultadoAnual.deudaTotalAnual;
        final estado = _determinarEstadoConsolidado(deudaTotal);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _mostrarDetalleNinoBottomSheet(nino, resultadoAnual),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Avatar del niño
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getEstadoColorLight(estado),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      Icons.child_care,
                      color: _getEstadoColorDark(estado),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Información del niño
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nino.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildEstadoBadge(estado, deudaTotal),
                      ],
                    ),
                  ),
                  // Indicador de navegación
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEstadoBadge(String estado, num deudaTotal) {
    final label = _getEstadoLabel(estado, deudaTotal);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: _getEstadoColorLight(estado),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getEstadoColorMedium(estado)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getEstadoIcon(estado),
            color: _getEstadoColorDark(estado),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getEstadoColorDark(estado),
            ),
          ),
        ],
      ),
    );
  }

  String _determinarEstadoConsolidado(num deudaTotal) {
    if (deudaTotal <= 0) {
      return 'al_dia';
    } else {
      // Verificar si hay algún abono parcial
      // Para simplificar, si debe algo, mostramos el estado según la deuda
      return 'debe';
    }
  }

  Color _getEstadoColorLight(String estado) {
    switch (estado) {
      case 'al_dia':
        return Colors.green.shade100;
      case 'debe':
        return Colors.red.shade100;
      case 'abono_parcial':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getEstadoColorMedium(String estado) {
    switch (estado) {
      case 'al_dia':
        return Colors.green.shade300;
      case 'debe':
        return Colors.red.shade300;
      case 'abono_parcial':
        return Colors.orange.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getEstadoColorDark(String estado) {
    switch (estado) {
      case 'al_dia':
        return Colors.green.shade700;
      case 'debe':
        return Colors.red.shade700;
      case 'abono_parcial':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'al_dia':
        return Icons.check_circle;
      case 'debe':
        return Icons.error;
      case 'abono_parcial':
        return Icons.pending;
      default:
        return Icons.help_outline;
    }
  }

  String _getEstadoLabel(String estado, num deudaTotal) {
    switch (estado) {
      case 'al_dia':
        return 'Al día';
      case 'debe':
        return 'Debe \$${deudaTotal.toStringAsFixed(0)}';
      case 'abono_parcial':
        return 'Abonó, debe \$${deudaTotal.toStringAsFixed(0)}';
      default:
        return 'Desconocido';
    }
  }

  void _mostrarDetalleNinoBottomSheet(Nino nino, dynamic resultadoAnual) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NinoDetalleBottomSheet(
        nino: nino,
        resultadoAnual: resultadoAnual,
      ),
    );
  }
}

/// BottomSheet para mostrar el detalle de pagos de un niño
class NinoDetalleBottomSheet extends StatelessWidget {
  final Nino nino;
  final dynamic resultadoAnual;

  const NinoDetalleBottomSheet({
    super.key,
    required this.nino,
    required this.resultadoAnual,
  });

  @override
  Widget build(BuildContext context) {
    // Extraer información del resultado anual
    final anio = resultadoAnual.anio;
    final valorCobro = resultadoAnual.valorCobro;
    final resultadosPorMes = resultadoAnual.resultadosPorMes as List;
    final deudaTotal = resultadoAnual.deudaTotalAnual;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Indicador de arrastre
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Encabezado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.child_care,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nino.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Año $anio',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Resumen de deuda
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: deudaTotal > 0
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    deudaTotal > 0
                        ? 'Debe \$${deudaTotal.toStringAsFixed(0)}'
                        : 'Al día',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: deudaTotal > 0
                          ? Colors.red.shade700
                          : Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          // Información de valor de cobro
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Valor mensual: \$${valorCobro.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Grid de meses
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final mes = index + 1;
                  final resultadoMes = resultadosPorMes[index];
                  
                  return _buildMesCard(mes, resultadoMes, valorCobro);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Botón cerrar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.grey.shade800,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMesCard(int mes, dynamic resultadoMes, num valorCobro) {
    final estado = resultadoMes.estado;
    final montoAbonado = resultadoMes.montoAbonadoDelMes;
    final saldoPendiente = resultadoMes.saldoPendienteDelMes;

    final colorLight = _getMesColorLight(estado);
    final colorDark = _getMesColorDark(estado);
    final nombreMes = _getNombreMes(mes);

    return Container(
      decoration: BoxDecoration(
        color: colorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getMesColorMedium(estado),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icono de estado
          Icon(
            _getMesIcon(estado),
            color: colorDark,
            size: 24,
          ),
          const SizedBox(height: 4),
          // Nombre del mes
          Text(
            nombreMes,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colorDark,
            ),
          ),
          const SizedBox(height: 4),
          // Monto abonado
          Text(
            '\$${montoAbonado.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          // Saldo pendiente si aplica
          if (saldoPendiente > 0)
            Text(
              'Pend: \$${saldoPendiente.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Color _getMesColorLight(String estado) {
    switch (estado) {
      case 'pagado':
        return Colors.green.shade50;
      case 'pendiente':
        return Colors.red.shade50;
      case 'abono_parcial':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getMesColorMedium(String estado) {
    switch (estado) {
      case 'pagado':
        return Colors.green.shade300;
      case 'pendiente':
        return Colors.red.shade300;
      case 'abono_parcial':
        return Colors.orange.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getMesColorDark(String estado) {
    switch (estado) {
      case 'pagado':
        return Colors.green.shade700;
      case 'pendiente':
        return Colors.red.shade700;
      case 'abono_parcial':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getMesIcon(String estado) {
    switch (estado) {
      case 'pagado':
        return Icons.check_circle;
      case 'pendiente':
        return Icons.error;
      case 'abono_parcial':
        return Icons.pending;
      default:
        return Icons.help_outline;
    }
  }

  String _getNombreMes(int mes) {
    const nombres = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return nombres[mes - 1];
  }
}