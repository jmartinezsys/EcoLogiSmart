import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_shell.dart';
import '../../models/company_account.dart';
import '../../services/account_repository.dart';
import '../../shared/colombian_city_field.dart';

class CompanyRegistrationScreen extends StatefulWidget {
  const CompanyRegistrationScreen({super.key});

  @override
  State<CompanyRegistrationScreen> createState() =>
      _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState extends State<CompanyRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _business = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  String? _location;
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String _sector = 'Turismo y hotelería';
  bool _hidePassword = true;
  bool _isRegistering = false;

  @override
  void dispose() {
    _business.dispose();
    _contact.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final account = CompanyAccount(
      businessName: _business.text.trim(),
      contactName: _contact.text.trim(),
      email: _email.text.trim().toLowerCase(),
      sector: _sector,
      city: _location ?? '',
    );
    setState(() => _isRegistering = true);
    try {
      final result = await AccountRepository.register(
        account: account,
        password: _password.text,
      );
      if (!mounted) return;
      if (result.emailConfirmationRequired) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirma tu correo'),
            content: Text(
              'Enviamos un enlace a ${account.email}. Confirma tu cuenta y luego inicia sesión.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.pop(context);
        return;
      }
      final registeredAccount = result.account;
      if (registeredAccount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya existe una cuenta con ese correo.')),
        );
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => AppShell(account: registeredAccount),
        ),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyAuthError(error.message))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No pudimos crear la cuenta. Revisa la conexión e inténtalo de nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  String _friendlyAuthError(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('already registered')) {
      return 'Ya existe una cuenta con ese correo.';
    }
    if (normalized.contains('password')) {
      return 'La contraseña no cumple los requisitos.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Crear cuenta de empresa'),
      leading: IconButton(
        tooltip: 'Volver al inicio de sesión',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
      ),
    ),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const Text(
              'Registra tu negocio',
              style: TextStyle(
                color: Color(0xFF1B3027),
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Crea el acceso y completa la información operativa básica.',
              style: TextStyle(color: Color(0xFF78847C), fontSize: 13),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _business,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre de la empresa',
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(),
              ),
              validator: _required('Ingresa el nombre de la empresa'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contact,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Persona de contacto',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: _required('Ingresa una persona de contacto'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _sector,
              decoration: const InputDecoration(
                labelText: 'Sector de actividad',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items:
                  const [
                        'Turismo y hotelería',
                        'Restaurante',
                        'Comercio',
                        'Servicios',
                        'Transporte',
                        'Otro',
                      ]
                      .map(
                        (sector) => DropdownMenuItem(
                          value: sector,
                          child: Text(sector),
                        ),
                      )
                      .toList(),
              onChanged: (sector) {
                if (sector != null) setState(() => _sector = sector);
              },
            ),
            const SizedBox(height: 14),
            ColombianCityField(
              key: const ValueKey('company-registration-city'),
              onChanged: (city) => setState(() => _location = city),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Escribe un correo válido'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _hidePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: _hidePassword
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () =>
                      setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(
                    _hidePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.length < 8
                  ? 'Usa al menos 8 caracteres'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPassword,
              obscureText: _hidePassword,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                prefixIcon: Icon(Icons.lock_reset_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value != _password.text
                  ? 'Las contraseñas no coinciden'
                  : null,
            ),
            const SizedBox(height: 18),
            Text(
              'La cuenta se guardará en ${AccountRepository.isCloudEnabled ? 'la nube' : 'este dispositivo (modo demostración)'}.',
              style: TextStyle(fontSize: 11, color: Color(0xFF78847C)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isRegistering ? null : _register,
              icon: const Icon(Icons.person_add_alt_1),
              label: _isRegistering
                  ? const Text('Creando cuenta…')
                  : const Text('Crear cuenta y continuar'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF173E35),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  String? Function(String?) _required(String message) =>
      (value) => value == null || value.trim().isEmpty ? message : null;
}
