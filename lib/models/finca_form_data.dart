class FincaFormData {
  final String nombre;
  final String? municipio;
  final double? areaHectareas;

  const FincaFormData({
    required this.nombre,
    this.municipio,
    this.areaHectareas,
  });

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'municipio': municipio,
        'areaHectareas': areaHectareas,
      };
}
