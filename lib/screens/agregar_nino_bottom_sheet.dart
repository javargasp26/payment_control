import 'package:flutter/material.dart';
import '../models/grupo.dart';
import '../models/nino.dart';
import '../services/grupo_service.dart';
import '../services/nino_service.dart';

/// Expresión regular para validar teléfonos: solo dígitos, largo razonable (7-10).
final RegExp _telefonoRegExp = RegExp(r'^\d{7,10}$');

/// BottomSheet para agregar un nuevo niño o editar uno existente.
///
/// Si `nino` es null, funciona en modo creación. Si se pasa un `Nino`
/// existente, precarga sus datos y funciona en modo edición (actualiza el
/// documento en vez de crear uno nuevo).
class AgregarNinoBottomSheet extends StatefulWidget {
  final Nino? nino;

  const AgregarNinoBottomSheet({super.key, this.nino});

  bool get esEdicion => nino != null;

  @override
  State<AgregarNinoBottomSheet> createState() => _AgregarNinoBottomSheetState();
}

class _AgregarNinoBottomSheetState extends State<AgregarNinoBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _segundoNombreController = TextEditingController();
  final _primerApellidoController = TextEditingController();
  final _segundoApellidoController = TextEditingController();
  final _telefonoContactoController = TextEditingController();
  final _nombreAcudienteController = TextEditingController();
  final _telefonoAcudienteController = TextEditingController();

  final _grupoService = GrupoService();
  final _ninoService = NinoService();

  String? _selectedGrupoId;
  DateTime? _fechaIngreso;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    final nino = widget.nino;
    if (nino != null) {
      // Modo edición: precargar los valores actuales del niño.
      _nombreController.text = nino.nombre;
      _segundoNombreController.text = nino.segundoNombre ?? '';
      _primerApellidoController.text = nino.primerApellido;
      _segundoApellidoController.text = nino.segundoApellido ?? '';
      _telefonoContactoController.text = nino.telefonoContacto ?? '';
      _nombreAcudienteController.text = nino.nombreAcudiente;
      _telefonoAcudienteController.text = nino.telefonoAcudiente;
      _selectedGrupoId = nino.grupoId;
      _fechaIngreso = nino.fechaIngreso;
    } else {
      // Modo creación: se sugiere la fecha actual, pero es editable por si
      // el ingreso real fue en un mes anterior.
      _fechaIngreso = DateTime.now();
    }

    // Recalcula la validez del formulario en cada cambio para habilitar/deshabilitar "Guardar".
    for (final controller in _todosLosControllers) {
      controller.addListener(_onFormChanged);
    }
  }

  List<TextEditingController> get _todosLosControllers => [
        _nombreController,
        _segundoNombreController,
        _primerApellidoController,
        _segundoApellidoController,
        _telefonoContactoController,
        _nombreAcudienteController,
        _telefonoAcudienteController,
      ];

  void _onFormChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _todosLosControllers) {
      controller.removeListener(_onFormChanged);
      controller.dispose();
    }
    super.dispose();
  }

  String? _validarNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa el nombre del niño';
    }
    return null;
  }

  String? _validarPrimerApellido(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa el primer apellido';
    }
    return null;
  }

  String? _validarTelefonoContacto(String? value) {
    if (value == null || value.trim().isEmpty) {
      // Opcional: vacío es válido
      return null;
    }
    if (!_telefonoRegExp.hasMatch(value.trim())) {
      return 'Ingresa solo números (7 a 10 dígitos)';
    }
    return null;
  }

  String? _validarNombreAcudiente(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa el nombre del acudiente';
    }
    return null;
  }

  String? _validarTelefonoAcudiente(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa el teléfono del acudiente';
    }
    if (!_telefonoRegExp.hasMatch(value.trim())) {
      return 'Ingresa solo números (7 a 10 dígitos)';
    }
    return null;
  }

  /// Determina si el formulario tiene todos los campos obligatorios completos
  /// y válidos, para habilitar el botón "Guardar".
  bool get _esFormularioValido {
    return _validarNombre(_nombreController.text) == null &&
        _validarPrimerApellido(_primerApellidoController.text) == null &&
        _validarTelefonoContacto(_telefonoContactoController.text) == null &&
        _validarNombreAcudiente(_nombreAcudienteController.text) == null &&
        _validarTelefonoAcudiente(_telefonoAcudienteController.text) == null &&
        _selectedGrupoId != null && _selectedGrupoId!.isNotEmpty &&
        _fechaIngreso != null;
  }

  Future<void> _seleccionarFechaIngreso() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
      helpText: 'Fecha de ingreso',
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaIngreso = fechaSeleccionada;
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    const nombresMeses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${fecha.day} de ${nombresMeses[fecha.month - 1]} de ${fecha.year}';
  }

  Future<void> _guardarNino() async {
    if (!_formKey.currentState!.validate() || !_esFormularioValido) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final segundoNombre = _segundoNombreController.text.trim().isEmpty
        ? null
        : _segundoNombreController.text.trim();
    final segundoApellido = _segundoApellidoController.text.trim().isEmpty
        ? null
        : _segundoApellidoController.text.trim();
    final telefonoContacto = _telefonoContactoController.text.trim().isEmpty
        ? null
        : _telefonoContactoController.text.trim();

    try {
      if (widget.esEdicion) {
        // El grupoId puede haber cambiado: el niño se reasigna al nuevo
        // grupo, y como los abonos se guardan asociados por ninoId, su
        // histórico de pagos no se ve afectado por este cambio.
        await _ninoService.actualizarNino(
          id: widget.nino!.id,
          nombre: _nombreController.text.trim(),
          segundoNombre: segundoNombre,
          primerApellido: _primerApellidoController.text.trim(),
          segundoApellido: segundoApellido,
          telefonoContacto: telefonoContacto,
          nombreAcudiente: _nombreAcudienteController.text.trim(),
          telefonoAcudiente: _telefonoAcudienteController.text.trim(),
          grupoId: _selectedGrupoId!,
          fechaIngreso: _fechaIngreso!,
        );
      } else {
        await _ninoService.crearNino(
          nombre: _nombreController.text.trim(),
          segundoNombre: segundoNombre,
          primerApellido: _primerApellidoController.text.trim(),
          segundoApellido: segundoApellido,
          telefonoContacto: telefonoContacto,
          nombreAcudiente: _nombreAcudienteController.text.trim(),
          telefonoAcudiente: _telefonoAcudienteController.text.trim(),
          grupoId: _selectedGrupoId!,
          fechaIngreso: _fechaIngreso!,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.esEdicion
                  ? 'Información actualizada correctamente'
                  : 'Niño agregado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = widget.esEdicion
            ? 'Error al actualizar el niño: ${e.toString()}'
            : 'Error al agregar el niño: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  InputDecoration _decoracion({
    required String label,
    String? hint,
    required IconData icono,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icono),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              // Título
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      widget.esEdicion ? Icons.edit : Icons.person_add,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.esEdicion ? 'Editar Niño' : 'Agregar Nuevo Niño',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              // Formulario scrolleable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Datos del niño',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 1. Nombre (obligatorio)
                        TextFormField(
                          controller: _nombreController,
                          decoration: _decoracion(
                            label: 'Nombre *',
                            hint: 'Ej: Juan',
                            icono: Icons.child_care,
                          ),
                          validator: _validarNombre,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        // 2. Segundo nombre (opcional)
                        TextFormField(
                          controller: _segundoNombreController,
                          decoration: _decoracion(
                            label: 'Segundo nombre',
                            hint: 'Ej: Andrés',
                            icono: Icons.child_care_outlined,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        // 3. Primer apellido (obligatorio)
                        TextFormField(
                          controller: _primerApellidoController,
                          decoration: _decoracion(
                            label: 'Primer apellido *',
                            hint: 'Ej: Pérez',
                            icono: Icons.badge,
                          ),
                          validator: _validarPrimerApellido,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        // 4. Segundo apellido (opcional)
                        TextFormField(
                          controller: _segundoApellidoController,
                          decoration: _decoracion(
                            label: 'Segundo apellido',
                            hint: 'Ej: Gómez',
                            icono: Icons.badge_outlined,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        // 5. Teléfono de contacto (opcional)
                        TextFormField(
                          controller: _telefonoContactoController,
                          decoration: _decoracion(
                            label: 'Teléfono de contacto',
                            hint: 'Ej: 3001234567',
                            icono: Icons.phone_android,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: _validarTelefonoContacto,
                        ),
                        const SizedBox(height: 16),
                        // 6. Selector de grupo (obligatorio)
                        StreamBuilder<List<Grupo>>(
                          stream: _grupoService.obtenerGruposStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error, color: Colors.red),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Error al cargar grupos: ${snapshot.error}',
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final grupos = snapshot.data ?? [];

                            if (grupos.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.orange.shade200),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.warning,
                                        color: Colors.orange.shade700),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No hay grupos disponibles',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Primero crea un grupo desde Administración',
                                      style: TextStyle(
                                        color: Colors.orange.shade600,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            return DropdownButtonFormField<String>(
                              initialValue: _selectedGrupoId,
                              decoration: _decoracion(
                                label: 'Seleccionar grupo *',
                                icono: Icons.group,
                              ),
                              items: grupos.map((grupo) {
                                return DropdownMenuItem<String>(
                                  value: grupo.id,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        grupo.nombre,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '\$${grupo.valorCobro.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGrupoId = value;
                                  _hasError = false;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor selecciona un grupo';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // Fecha de ingreso (obligatoria)
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _seleccionarFechaIngreso,
                          child: InputDecorator(
                            decoration: _decoracion(
                              label: 'Fecha de ingreso *',
                              icono: Icons.event,
                            ),
                            child: Text(
                              _fechaIngreso != null
                                  ? _formatearFecha(_fechaIngreso!)
                                  : 'Selecciona una fecha',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Datos del acudiente',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 7. Nombre del acudiente (obligatorio)
                        TextFormField(
                          controller: _nombreAcudienteController,
                          decoration: _decoracion(
                            label: 'Nombre del acudiente *',
                            hint: 'Ej: María Pérez',
                            icono: Icons.family_restroom,
                          ),
                          validator: _validarNombreAcudiente,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 16),
                        // 8. Teléfono del acudiente (obligatorio)
                        TextFormField(
                          controller: _telefonoAcudienteController,
                          decoration: _decoracion(
                            label: 'Teléfono del acudiente *',
                            hint: 'Ej: 3001234567',
                            icono: Icons.phone,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: _validarTelefonoAcudiente,
                        ),
                        const SizedBox(height: 16),
                        // Mensaje de error
                        if (_hasError)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Botón guardar
                        ElevatedButton(
                          onPressed: (_isLoading || !_esFormularioValido)
                              ? null
                              : _guardarNino,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.esEdicion
                                      ? 'Guardar cambios'
                                      : 'Guardar Niño',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
