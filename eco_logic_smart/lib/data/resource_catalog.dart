class ResourceCatalog {
  ResourceCatalog._();

  static const categories = <String>[
    'Empaques y envases',
    'Plásticos',
    'Papel y cartón',
    'Metales',
    'Vidrio',
    'Madera',
    'Textiles',
    'Residuos orgánicos',
    'Aceites usados',
    'Electrónicos',
    'Construcción',
    'Químicos',
    'Agua y energía',
    'Maquinaria y equipos',
    'Insumos operativos',
    'Otro',
  ];

  static const productsByCategory = <String, List<String>>{
    'Empaques y envases': [
      'Cajas de cartón',
      'Estibas / pallets',
      'Canastillas plásticas',
      'Tambores reutilizables',
      'Botellas y frascos',
      'Película stretch',
    ],
    'Plásticos': [
      'PET',
      'PEAD / HDPE',
      'PEBD / LDPE',
      'Polipropileno',
      'PVC',
      'Poliestireno',
      'Plástico mixto',
    ],
    'Papel y cartón': [
      'Cartón corrugado',
      'Papel blanco',
      'Papel periódico',
      'Archivo y oficina',
      'Papel kraft',
    ],
    'Metales': [
      'Aluminio',
      'Acero',
      'Chatarra ferrosa',
      'Cobre',
      'Bronce',
      'Metales mixtos',
    ],
    'Vidrio': [
      'Vidrio transparente',
      'Vidrio ámbar',
      'Vidrio verde',
      'Vidrio mixto',
    ],
    'Madera': [
      'Estibas',
      'Aserrín',
      'Retales de madera',
      'Madera reutilizable',
    ],
    'Textiles': ['Retales textiles', 'Uniformes', 'Estopas', 'Fibras textiles'],
    'Residuos orgánicos': [
      'Residuos de alimentos',
      'Residuos vegetales',
      'Borra de café',
      'Lodos orgánicos',
    ],
    'Aceites usados': [
      'Aceite vegetal usado',
      'Aceite lubricante usado',
      'Grasas',
    ],
    'Electrónicos': [
      'Equipos de cómputo',
      'Cables',
      'Baterías',
      'Luminarias',
      'Aparatos eléctricos',
    ],
    'Construcción': [
      'Escombros limpios',
      'Madera de obra',
      'Retales metálicos',
      'Agregados recuperados',
    ],
    'Químicos': [
      'Solventes recuperables',
      'Envases químicos vacíos',
      'Reactivos vencidos',
    ],
    'Agua y energía': [
      'Agua recuperada',
      'Energía excedente',
      'Vapor',
      'Aire comprimido',
    ],
    'Maquinaria y equipos': [
      'Maquinaria usada',
      'Repuestos',
      'Herramientas',
      'Mobiliario industrial',
    ],
    'Insumos operativos': [
      'Elementos de protección personal',
      'Material de oficina',
      'Insumos de limpieza',
      'Contenedores',
    ],
  };

  static List<String> productsFor(String category) =>
      productsByCategory[category] ?? const [];

  static List<String> get allProducts =>
      productsByCategory.values.expand((products) => products).toSet().toList()
        ..sort();

  static const units = <String>[
    'unidades',
    'kg',
    'toneladas',
    'g',
    'litros',
    'm³',
    'm²',
    'cajas',
    'estibas',
    'kWh',
  ];
}
