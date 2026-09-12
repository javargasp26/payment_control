import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/grupo.dart';
import '../services/grupo_service.dart';

/// BottomSheet para crear o editar un grupo
class GrupoFormBottomSheet extends StatefulWidget {
  final Grupo? grupo; // Si es null, es crear; si tiene valor, es editar

  const GrupoFormBottomSheet({
    super.key,
    this.grupo,
  });

  @override
  State<GrupoFormBottomSheet> createState() => _GrupoFormBottomSheetState();
}

class _GrupoFormBottomSheetState extends State<GrupoFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _valorCobroController = TextEditingController();
  final _grupoService = GrupoService();
  
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Si estamos editando, precargar los valores
    if (widget.grupo != null) {
      _nombreController.text = widget.grupo!.nombre;
      _valorCobroController.text = widget.grupo!.valorCobro.toString();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _valorCobroController.dispose();
    super.dispose();
  }

  num _parseCurrency(String value) {
    // Eliminar comas y convertir a número
    String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.isEmpty) return 0;
    return int.parse(cleanValue);
  }

  Future<void> _guardarGrupo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final nombre = _nombreController.text.trim();
      final valorCobro = _parseCurrency(_valorCobroController.text);

      if (widget.grupo == null) {
        // Crear nuevo grupo
        await _grupoService.crearGrupo(
          nombre: nombre,
          valorCobro: valorCobro,
        );
      } else {
        // Actualizar grupo existente
        await _grupoService.actualizarGrupo(
          id: widget.grupo!.id,
          nombre: nombre,
          valorCobro: valorCobro,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.grupo == null
                  ? 'Grupo creado exitosamente'
                  : 'Grupo actualizado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Error al guardar el grupo: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.grupo != null;

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
                  isEditing ? Icons.edit : Icons.group_add,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Editar Grupo' : 'Crear Nuevo Grupo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          // Formulario
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo nombre
                  TextFormField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre del grupo',
                      hintText: 'Ej: Iniciación Musical',
                      prefixIcon: const Icon(Icons.group),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa el nombre del grupo';
                      }
                      return null;
                    },
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  // Campo valor de cobro
                  TextFormField(
                    controller: _valorCobroController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Valor de cobro mensual',
                      hintText: 'Ej: 50,000',
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixIcon: const Icon(Icons.info_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa el valor de cobro';
                      }
                      final valor = _parseCurrency(value);
                      if (valor <= 0) {
                        return 'El valor de cobro debe ser mayor a 0';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 8),
                  // Información adicional
                  Text(
                    'El valor se mostrará con formato de moneda',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
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
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
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
                    onPressed: _isLoading ? null : _guardarGrupo,
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isEditing ? 'Actualizar Grupo' : 'Crear Grupo',
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
        ],
      ),
    );
  }
}

/// Formateador de entrada para moneda
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eliminar cualquier caracter que no sea dígito
    String cleanValue = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanValue.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Convertir a número y formatear con separadores de miles
    try {
      int number = int.parse(cleanValue);
      String formatted = number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
      
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    } catch (e) {
      return newValue;
    }
  }
}