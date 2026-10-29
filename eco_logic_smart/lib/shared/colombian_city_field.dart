import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColombianLocation {
  const ColombianLocation({
    required this.municipality,
    required this.department,
    required this.type,
  });

  final String municipality;
  final String department;
  final String type;

  String get label => '$municipality, $department';

  factory ColombianLocation.fromJson(Map<String, dynamic> json) =>
      ColombianLocation(
        municipality: _titleCase(json['municipality'] as String? ?? ''),
        department: _titleCase(json['department'] as String? ?? ''),
        type: json['type'] as String? ?? 'Municipio',
      );
}

class ColombianCityField extends StatefulWidget {
  const ColombianCityField({super.key, required this.onChanged});

  final ValueChanged<String?> onChanged;

  @override
  State<ColombianCityField> createState() => _ColombianCityFieldState();
}

class _ColombianCityFieldState extends State<ColombianCityField> {
  List<ColombianLocation> _locations = const [];
  bool _loading = true;
  bool _loadFailed = false;
  ColombianLocation? _selected;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final json = await rootBundle.loadString(
        'assets/data/colombia_divipola.json',
      );
      final rows = (jsonDecode(json) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final locations = rows.map(ColombianLocation.fromJson).toList()
        ..sort((a, b) {
          final departmentOrder = a.department.compareTo(b.department);
          return departmentOrder != 0
              ? departmentOrder
              : a.municipality.compareTo(b.municipality);
        });
      if (!mounted) return;
      setState(() {
        _locations = locations;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Autocomplete<ColombianLocation>(
    displayStringForOption: (location) => location.label,
    optionsBuilder: (value) {
      final query = _fold(value.text.trim());
      if (_loading || query.length < 2) return const [];
      return _locations
          .where((location) => _fold(location.label).contains(query))
          .take(12);
    },
    onSelected: (location) {
      setState(() => _selected = location);
      widget.onChanged(location.label);
    },
    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) =>
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: !_loading && !_loadFailed,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Ciudad o zona',
            hintText: _loading ? 'Cargando municipios…' : 'Escribe para buscar',
            prefixIcon: const Icon(Icons.location_on_outlined),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : const Icon(Icons.search),
            helperText: _loadFailed
                ? 'No se pudo cargar el catálogo. Reinicia la aplicación.'
                : 'Selecciona un municipio y su departamento.',
          ),
          validator: (value) {
            if (_loadFailed) return 'No se pudo cargar la lista de ciudades';
            if (_selected == null || controller.text != _selected!.label) {
              return 'Selecciona una opción de la lista';
            }
            return null;
          },
          onChanged: (value) {
            if (_selected != null && value != _selected!.label) {
              setState(() => _selected = null);
              widget.onChanged(null);
            }
          },
        ),
    optionsViewBuilder: (context, onSelected, options) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280, maxWidth: 430),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final location = options.elementAt(index);
              return ListTile(
                dense: true,
                leading: const Icon(Icons.location_city_outlined),
                title: Text(location.municipality),
                subtitle: Text(location.department),
                onTap: () => onSelected(location),
              );
            },
          ),
        ),
      ),
    ),
  );

  String _fold(String value) => value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n');
}

String _titleCase(String value) => value
    .toLowerCase()
    .split(RegExp(r'\s+'))
    .map(
      (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    )
    .join(' ');
