import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';
import '../widgets/comunes.dart';
import '../utils/responsive.dart';

/// Cambiar contraseña (pestaña "Seguridad")
class CambiarPasswordScreen extends StatefulWidget {
  final bool enPestana;
  const CambiarPasswordScreen({super.key, this.enPestana = false});

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  final _confirmar = TextEditingController();
  bool _ocultar = true;
  bool _guardando = false;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      await context.read<AuthProvider>().cambiarPassword(_actual.text, _nueva.text);
      if (!mounted) return;
      _actual.clear();
      _nueva.clear();
      _confirmar.clear();
      mostrarMensaje(context, 'Contraseña actualizada');
      if (!widget.enPestana) Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ojo = IconButton(
      icon: Icon(_ocultar ? Icons.visibility_off : Icons.visibility),
      onPressed: () => setState(() => _ocultar = !_ocultar),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña'), automaticallyImplyLeading: !widget.enPestana),
      body: SingleChildScrollView(
        padding: Responsive.padding(context, maxAncho: 560),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.azulClaro,
                  child: Icon(Icons.lock, size: 36, color: AppColors.azul),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Mantén tu cuenta segura',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.gris)),
              const SizedBox(height: 20),
              CampoTexto(
                etiqueta: 'Contraseña actual',
                icono: Icons.lock_outline,
                controller: _actual,
                oculto: _ocultar,
                sufijo: ojo,
                validator: (v) => Validadores.requerido(v, 'Contraseña actual'),
              ),
              CampoTexto(
                etiqueta: 'Nueva contraseña',
                icono: Icons.lock_reset,
                controller: _nueva,
                oculto: _ocultar,
                validator: (v) {
                  final e = Validadores.password(v);
                  if (e != null) return e;
                  if (v == _actual.text) return 'Debe ser distinta a la actual';
                  return null;
                },
              ),
              CampoTexto(
                etiqueta: 'Confirmar nueva contraseña',
                icono: Icons.lock_reset,
                controller: _confirmar,
                oculto: _ocultar,
                validator: (v) => v != _nueva.text ? 'Las contraseñas no coinciden' : null,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _guardando ? null : _guardar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: const Text('Actualizar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
