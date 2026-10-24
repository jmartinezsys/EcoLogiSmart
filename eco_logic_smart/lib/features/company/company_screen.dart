import 'package:flutter/material.dart';

import '../../shared/components.dart';
import '../auth/login_screen.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});
  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _business = TextEditingController(text: 'Hotel Bahía Verde');
  final _contact = TextEditingController(text: 'Andrea Martínez');
  final _location = TextEditingController(text: 'Cartagena, Bolívar');
  String _sector = 'Turismo y hotelería';
  @override
  void dispose() {
    _business.dispose();
    _contact.dispose();
    _location.dispose();
    super.dispose();
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
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
            (route) => false,
          ),
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
                    'Información operativa',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF254A35),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Usamos estos datos para organizar recursos y conectar oportunidades entre negocios.',
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
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa el nombre del negocio'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contact,
              decoration: const InputDecoration(
                labelText: 'Persona de contacto',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa un contacto'
                  : null,
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
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _sector = value);
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Ciudad o zona',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa una ubicación'
                  : null,
            ),
            const SizedBox(height: 22),
            const SectionTitle('Privacidad y alcance'),
            const InfoCard(
              icon: Icons.lock_outline,
              title: 'Tus finanzas no son necesarias',
              subtitle:
                  'No solicitamos ingresos, recaudos, cuentas bancarias ni estados financieros.',
              color: Color(0xFFEAF2EA),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Perfil guardado en esta demostración'),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Guardar información'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
