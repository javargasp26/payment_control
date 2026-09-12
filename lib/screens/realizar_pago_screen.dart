import 'package:flutter/material.dart';
import '../models/nino.dart';
import '../models/grupo.dart';
import '../models/abono.dart';
import '../services/nino_service.dart';
import '../services/grupo_service.dart';
import '../services/abono_service.dart';
import '../services/calculo_service.dart';

/// Pantalla para realizar pagos de niños
/// Permite buscar un niño por nombre y registrar abonos rápidamente
class RealizarPagoScreen extends StatefulWidget {
  const RealizarPagoScreen({super.key});

  @override
  State<RealizarPagoScreen> createState() => _RealizarPagoScreenState();
}

class _RealizarPagoScreenState extends State<RealizarPagoScreen> {
  final NinoService _ninoService = NinoService();
  final GrupoService _grupoService = GrupoService();
  final AbonoService _abonoService = AbonoService();

  // Controladores y estado
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  
  Nino? _ninoSeleccionado;
  Grupo? _grupoSeleccionado;
  List<Nino> _todosLosNinos = [];
  List<Nino> _ninosFiltrados = [];
  int? _mesSeleccionado;
  bool _cargandoNinos = true;
  String? _errorCarga;

  @override
  void initState() {
    super.initState();
    _cargarNinos();
    _searchController.addListener(_filtrarNinos);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  /// Carga todos los niños al iniciar
  /// NOTA: Esta implementación trae todos los niños y filtra en memoria.
  /// Para producción con muchos niños, considerar usar índices de búsqueda
  /// en Firestore o un servicio de búsqueda dedicado.
  Future<void> _cargarNinos() async {
    try {
      final ninos = await _ninoService.obtenerNinosStream().first;
      setState(() {
        _todosLosNinos = ninos;
        _ninosFiltrados = ninos;
        _cargandoNinos = false;
      });
    } catch (e) {
      setState(() {
        _errorCarga = e.toString();
        _cargandoNinos = false;
      });
    }
  }

  /// Filtra los niños por nombre (búsqueda parcial, case-insensitive)
  void _filtrarNinos() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      if (query.isEmpty) {
        _ninosFiltrados = _todosLosNinos;
      } else {
        _ninosFiltrados = _todosLosNinos
            .where((nino) => nino.nombre.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  /// Selecciona un niño y carga su grupo
  Future<void> _seleccionarNino(Nino nino) async {
    setState(() {
      _ninoSeleccionado = nino;
      _grupoSeleccionado = null;
      _mesSeleccionado = null;
      _montoController.clear();
    });

    try {
      final grupo = await _grupoService.obtenerGrupoPorId(nino.grupoId);
      if (mounted) {
        setState(() {
          _grupoSeleccionado = grupo;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar el grupo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realizar Pago'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Campo de búsqueda
        _buildSearchField(),
        
        // Contenido principal
        Expanded(
          child: _ninoSeleccionado == null
              ? _buildListaResultados()
              : _buildDetalleNino(),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar niño por nombre...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _buildListaResultados() {
    if (_cargandoNinos) {
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

    if (_errorCarga != null) {
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
                _errorCarga!,
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

    if (_ninosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Busca un niño por su nombre para ver su estado y registrar un pago.'
                  : 'No se encontraron niños con ese nombre.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _ninosFiltrados.length,
      itemBuilder: (context, index) {
        final nino = _ninosFiltrados[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                nino.nombre[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              nino.nombre,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _seleccionarNino(nino),
          ),
        );
      },
    );
  }

  Widget _buildDetalleNino() {
    if (_grupoSeleccionado == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final anioActual = DateTime.now().year;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del niño
          _buildInfoNino(),
          const SizedBox(height: 24),
          
          // Cuadrícula de meses
          _buildCuadriculaMeses(anioActual),
          const SizedBox(height: 24),
          
          // Formulario de pago
          _buildFormularioPago(anioActual),
        ],
      ),
    );
  }

  Widget _buildInfoNino() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  radius: 24,
                  child: Text(
                    _ninoSeleccionado!.nombre[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ninoSeleccionado!.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grupo: ${_grupoSeleccionado!.nombre}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Valor mensual:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '\$${_grupoSeleccionado!.valorCobro.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
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
    );
  }

  Widget _buildCuadriculaMeses(int anio) {
    return StreamBuilder<List<Abono>>(
      stream: _abonoService.obtenerAbonosPorNinoYAnioStream(
        ninoId: _ninoSeleccionado!.id,
        anio: anio,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: \${snapshot.error}'),
          );
        }

        final abonos = snapshot.data ?? [];
        final resultadoAnual = CalculoService.calcularResultadoAnual(
          nino: _ninoSeleccionado!,
          grupo: _grupoSeleccionado!,
          abonos: abonos,
          anio: anio,
        );

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado de pagos - $anio',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calcular número de columnas según el ancho disponible
                    final ancho = constraints.maxWidth;
                    int columnas;
                    double aspectRatio;
                    
                    if (ancho < 400) {
                      // Celular angosto: 3 columnas (4 filas)
                      columnas = 3;
                      aspectRatio = 1.3;
                    } else if (ancho < 700) {
                      // Celular grande / tablet chica: 4 columnas (3 filas)
                      columnas = 4;
                      aspectRatio = 1.4;
                    } else {
                      // Tablet grande / escritorio: 6 columnas (2 filas)
                      columnas = 6;
                      aspectRatio = 1.5;
                    }
                    
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnas,
                        childAspectRatio: aspectRatio,
                        crossAxisSpacing: 6,
                        mainAxisSpacing: 6,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final mes = index + 1;
                        final resultado = resultadoAnual.obtenerResultadoMes(mes);
                        return _buildMesCard(resultado!);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMesCard(ResultadoMes resultado) {
    final nombresMeses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];

    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (resultado.estado) {
      case 'pagado':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'pendiente':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.error;
        break;
      case 'abono_parcial':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.pending;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(height: 2),
          Text(
            nombresMeses[resultado.mes - 1],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '\$${resultado.saldoPendienteDelMes.toStringAsFixed(0)}',
            style: TextStyle(
              color: textColor,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioPago(int anio) {
    return StreamBuilder<List<Abono>>(
      stream: _abonoService.obtenerAbonosPorNinoYAnioStream(
        ninoId: _ninoSeleccionado!.id,
        anio: anio,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final abonos = snapshot.data ?? [];
        final resultadoAnual = CalculoService.calcularResultadoAnual(
          nino: _ninoSeleccionado!,
          grupo: _grupoSeleccionado!,
          abonos: abonos,
          anio: anio,
        );

        // Preseleccionar el primer mes con saldo pendiente
        if (_mesSeleccionado == null) {
          for (int mes = 1; mes <= 12; mes++) {
            final resultado = resultadoAnual.obtenerResultadoMes(mes);
            if (resultado != null && resultado.saldoPendienteDelMes > 0) {
              _mesSeleccionado = mes;
              break;
            }
          }
          // Si no hay meses pendientes, preseleccionar enero
          _mesSeleccionado ??= 1;
        }

        final resultadoMesSeleccionado = resultadoAnual.obtenerResultadoMes(_mesSeleccionado!);

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrar nuevo abono',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Selector de mes
                DropdownButtonFormField<int>(
                  key: ValueKey('mes_\${_ninoSeleccionado!.id}'),
                  value: _mesSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Mes',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(12, (index) {
                    final mes = index + 1;
                    final resultado = resultadoAnual.obtenerResultadoMes(mes);
                    return DropdownMenuItem(
                      value: mes,
                      child: Text(
                        _getNombreMes(mes),
                        style: TextStyle(
                          color: resultado?.estado == 'pagado' 
                              ? Colors.green 
                              : null,
                        ),
                      ),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _mesSeleccionado = value;
                      _montoController.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Campo de monto
                TextField(
                  key: ValueKey('monto_${_ninoSeleccionado!.id}_$_mesSeleccionado'),
                  controller: _montoController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto a abonar',
                    prefixText: '\$ ',
                    border: const OutlineInputBorder(),
                    helperText: resultadoMesSeleccionado != null
                        ? 'Saldo pendiente: \$${resultadoMesSeleccionado.saldoPendienteDelMes.toStringAsFixed(2)}'
                        : '',
                  ),
                ),
                const SizedBox(height: 16),
                
                // Botón de registrar
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _montoController,
                  builder: (context, value, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: ValueKey('registrar_\${_ninoSeleccionado!.id}'),
                        onPressed: value.text.isNotEmpty 
                            ? () => _registrarAbono(anio)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                        'Registrar pago',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getNombreMes(int mes) {
    const nombres = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return nombres[mes - 1];
  }

  Future<void> _registrarAbono(int anio) async {
    final montoText = _montoController.text.trim();
    
    if (montoText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un monto')),
      );
      return;
    }

    final monto = double.tryParse(montoText);
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El monto debe ser mayor a 0')),
      );
      return;
    }

    try {
      final resultado = await _abonoService.registrarAbonoConDistribucion(
        ninoId: _ninoSeleccionado!.id,
        grupo: _grupoSeleccionado!,
        anio: anio,
        mesSeleccionado: _mesSeleccionado!,
        montoTotal: monto,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensajeConfirmacion),
            backgroundColor: Colors.green,
          ),
        );

        // Limpiar el formulario para permitir registrar otro pago
        setState(() {
          _montoController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al registrar el pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
