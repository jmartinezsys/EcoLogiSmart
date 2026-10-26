import 'package:flutter/material.dart';

import '../../models/company_account.dart';
import '../../services/account_repository.dart';
import '../../shared/components.dart';
import '../auth/splash_screen.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key, required this.account});

  final CompanyAccount account;

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _business = TextEditingController(
    text: widget.account.businessName,
  );
  late final _contact = TextEditingController(text: widget.account.contactName);
  late final _location = TextEditingController(text: widget.account.city);
  late String _sector = widget.account.sector;

  @override
  void dispose() {
    _business.dispose();
    _contact.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.account.copyWith(
      businessName: _business.text.trim(),
      contactName: _contact.text.trim(),
      city: _location.text.trim(),
      sector: _sector,
    );
    await AccountRepository.updateProfile(updated);
    if (mounted) Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Perfil de empresa'),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: () async {
            await AccountRepository.signOut();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const SplashScreen()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.logout_rounded),
        ),
      ],
    ),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE4F1E7),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.business_outlined,
                    color: Color(0xFF39815D),
                    size: 30,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Información de tu empresa',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF254A35),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Estos datos identifican tu espacio de trabajo y sus publicaciones.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF597260)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionTitle('Datos del negocio'),
            TextFormField(
              controller: _business,
              decoration: const InputDecoration(
                labelText: 'Nombre del negocio',
                border: OutlineInputBorder(),
              ),
              validator: _required('Ingresa el nombre del negocio'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contact,
              decoration: const InputDecoration(
                labelText: 'Persona de contacto',
                border: OutlineInputBorder(),
              ),
              validator: _required('Ingresa una persona de contacto'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _sector,
              decoration: const InputDecoration(
                labelText: 'Sector',
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
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Ciudad o zona',
                border: OutlineInputBorder(),
              ),
              validator: _required('Ingresa la ciudad o zona'),
            ),
            const SizedBox(height: 14),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Correo de acceso',
                border: OutlineInputBorder(),
              ),
              child: Text(widget.account.email),
            ),
            const SizedBox(height: 18),
            const InfoCard(
              icon: Icons.lock_outline,
              title: 'Información financiera privada',
              subtitle:
                  'No solicitamos ingresos, cuentas bancarias ni estados financieros.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.check),
              label: const Text('Guardar perfil'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
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
