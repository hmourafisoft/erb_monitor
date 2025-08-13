import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// Sistema centralizado de tratamento de erros para o ERB Monitor
class ErrorHandler {
  static const String _tag = 'ErrorHandler';
  
  /// Trata erros de forma centralizada e segura
  static void handleError(
    dynamic error, 
    dynamic stackTrace, {
    String? context,
    bool showUserMessage = true,
    BuildContext? buildContext,
  }) {
    // Log do erro para debugging
    developer.log(
      '❌ Erro em $context: $error',
      name: _tag,
      error: error,
      stackTrace: stackTrace,
    );
    
    // Mostrar mensagem para o usuário se necessário
    if (showUserMessage && buildContext != null) {
      _showErrorSnackBar(buildContext, error.toString());
    }
  }
  
  /// Mostra uma mensagem de erro para o usuário
  static void _showErrorSnackBar(BuildContext context, String message) {
    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: ${message.length > 100 ? '${message.substring(0, 100)}...' : message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Fechar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e) {
      developer.log('Erro ao mostrar SnackBar: $e', name: _tag);
    }
  }
  
  /// Executa uma função com tratamento de erro
  static Future<T?> safeExecute<T>(
    Future<T> Function() function, {
    String? context,
    T? defaultValue,
    bool showUserMessage = false,
    BuildContext? buildContext,
  }) async {
    try {
      return await function();
    } catch (error, stackTrace) {
      handleError(
        error, 
        stackTrace,
        context: context,
        showUserMessage: showUserMessage,
        buildContext: buildContext,
      );
      return defaultValue;
    }
  }
  
  /// Executa uma função síncrona com tratamento de erro
  static T? safeExecuteSync<T>(
    T Function() function, {
    String? context,
    T? defaultValue,
    bool showUserMessage = false,
    BuildContext? buildContext,
  }) {
    try {
      return function();
    } catch (error, stackTrace) {
      handleError(
        error, 
        stackTrace,
        context: context,
        showUserMessage: showUserMessage,
        buildContext: buildContext,
      );
      return defaultValue;
    }
  }
}

