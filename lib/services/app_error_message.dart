import 'package:firebase_auth/firebase_auth.dart';

import 'json_bin_exception.dart';

/// Converte erros técnicos do Firebase em mensagens claras para o usuário.
class AppErrorMessage {
  static String forOperation(Object error, {required String operation}) {
    if (error is JsonBinException) {
      final message = switch (error.statusCode) {
        401 || 403 =>
          'Não foi possível acessar o catálogo. Verifique as permissões da API.',
        404 => 'O catálogo ou produto não foi encontrado.',
        429 || 500 || 502 || 503 =>
          'O serviço está indisponível no momento. Tente novamente em alguns minutos.',
        _ => error.message,
      };
      final details = [
        if (error.stage != null) error.stage!,
        if (error.method != null) error.method!,
        if (error.statusCode != null) 'HTTP ${error.statusCode}',
      ];
      return details.isEmpty ? message : '$message (${details.join(' · ')}).';
    }
    final code = error is FirebaseException ? error.code : '';
    if (_isConnectionError(code, error)) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    }
    if (code == 'permission-denied') {
      return 'Você não tem permissão para realizar esta operação.';
    }
    if (code == 'unauthenticated') {
      return 'Sua sessão expirou. Entre novamente para continuar.';
    }
    if (code == 'unavailable') {
      return 'O serviço está indisponível no momento. Tente novamente em alguns minutos.';
    }
    if (code == 'not-found') {
      return 'O item não foi encontrado. Atualize a tela e tente novamente.';
    }
    if (code == 'already-exists') {
      return 'Já existe um registro com estes dados.';
    }

    return switch (operation) {
      'consulta' => 'Não foi possível consultar os dados. Tente novamente.',
      'cadastro' => 'Não foi possível concluir o cadastro. Tente novamente.',
      'alteração' => 'Não foi possível salvar as alterações. Tente novamente.',
      'exclusão' => 'Não foi possível excluir o item. Tente novamente.',
      _ => 'Ocorreu um erro inesperado. Tente novamente.',
    };
  }

  static bool _isConnectionError(String code, Object error) {
    const connectionCodes = {
      'network-request-failed',
      'deadline-exceeded',
      'cancelled',
      'failed-precondition',
    };
    final description = error.toString().toLowerCase();
    return connectionCodes.contains(code) ||
        description.contains('socketexception') ||
        description.contains('network') ||
        description.contains('connection');
  }

  static String forAuth(FirebaseAuthException error) {
    if (_isConnectionError(error.code, error)) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    }
    return switch (error.code) {
      'invalid-email' => 'Digite um e-mail válido.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => 'E-mail ou senha inválidos.',
      'email-already-in-use' => 'Este e-mail já está cadastrado.',
      'weak-password' => 'A senha deve ter pelo menos 6 caracteres.',
      'too-many-requests' =>
        'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
      'user-disabled' => 'Esta conta foi desativada.',
      _ => 'Não foi possível concluir a operação. Tente novamente.',
    };
  }
}
