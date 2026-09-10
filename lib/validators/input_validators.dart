class InputValidators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe seu e-mail';
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
    return valid ? null : 'Digite um e-mail válido';
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Informe seu telefone';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 ? null : 'Digite um telefone válido';
  }
}
