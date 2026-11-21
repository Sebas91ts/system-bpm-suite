class AppUser {
  const AppUser({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.roles,
    required this.activo,
    this.areaId,
    this.areaNombre,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final List<String> roles;
  final bool activo;
  final String? areaId;
  final String? areaNombre;
  final String? fechaCreacion;
  final String? fechaActualizacion;

  String get fullName => '$nombre $apellido'.trim();
  bool get isClient => roles.contains('ROLE_CLIENT');

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as String?) ?? '',
      nombre: (json['nombre'] as String?) ?? '',
      apellido: (json['apellido'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      roles: _asStringList(json['roles']),
      activo: json['activo'] == true,
      areaId: json['areaId'] as String?,
      areaNombre: json['areaNombre'] as String?,
      fechaCreacion: json['fechaCreacion'] as String?,
      fechaActualizacion: json['fechaActualizacion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'roles': roles,
      'activo': activo,
      'areaId': areaId,
      'areaNombre': areaNombre,
      'fechaCreacion': fechaCreacion,
      'fechaActualizacion': fechaActualizacion,
    };
  }
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String token;
  final String tokenType;
  final int expiresIn;
  final AppUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: (json['token'] as String?) ?? '',
      tokenType: (json['tokenType'] as String?) ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      user: AppUser.fromJson(Map<String, dynamic>.from(json['usuario'] as Map? ?? const {})),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
      'usuario': user.toJson(),
    };
  }
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }

  return const <String>[];
}
