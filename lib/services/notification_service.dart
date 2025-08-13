import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../utils/error_handler.dart';
import '../models/notification_models.dart';

/// Serviço otimizado para gerenciar notificações com tratamento de erros robusto
class NotificationService {
  static const String _tag = 'NotificationService';
  
  // Stream controllers para notificações
  final StreamController<TuyaNotification> _tuyaController = StreamController<TuyaNotification>.broadcast();
  final StreamController<TuyaNotification> _miboController = StreamController<TuyaNotification>.broadcast();
  final StreamController<TuyaNotification> _allController = StreamController<TuyaNotification>.broadcast();
  
  // Stream controller para logs de sistema
  final StreamController<LogEntry> _logController = StreamController<LogEntry>.broadcast();
  
  // Streams públicos
  Stream<TuyaNotification> get tuyaStream => _tuyaController.stream;
  Stream<TuyaNotification> get miboStream => _miboController.stream;
  Stream<TuyaNotification> get allStream => _allController.stream;
  Stream<LogEntry> get logStream => _logController.stream;
  
  // Configurações
  static const String _tuyaEndpoint = 'https://mvaqkxfptgkudqbvuxer.supabase.co/functions/v1/create-alarm';
  static const Duration _requestTimeout = Duration(seconds: 10);
  static const int _maxRetries = 3;
  
  // Cache para evitar duplicatas
  final Set<String> _processedNotifications = <String>{};
  final int _maxCacheSize = 1000;
  
  /// Processa uma nova notificação de forma segura
  void processNotification(TuyaNotification notification) {
    try {
      // Verificar se já foi processada
      final notificationKey = '${notification.id}_${notification.postTime}';
      if (_processedNotifications.contains(notificationKey)) {
        return;
      }
      
      // Adicionar ao cache
      _addToCache(notificationKey);
      
      // Limpeza automática a cada 20 notificações
      if (_processedNotifications.length % 20 == 0) {
        _cleanupOldNotifications();
      }
      
      // Enviar para stream geral
      _allController.add(notification);
      
      // Processar baseado no tipo
      if (_isTuyaNotification(notification)) {
        _tuyaController.add(notification);
        _processTuyaNotification(notification);
      } else if (_isMiboNotification(notification)) {
        _miboController.add(notification);
        _processMiboNotification(notification);
      }
      
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error, 
        stackTrace,
        context: 'processNotification',
        showUserMessage: false,
      );
    }
  }
  
  /// Processa notificação Tuya
  Future<void> _processTuyaNotification(TuyaNotification notification) async {
    try {
      final deviceInfo = _extractTuyaDeviceInfo(notification);
      if (deviceInfo != null) {
        await _sendAlarmToEndpoint(deviceInfo, 'tuya');
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error, 
        stackTrace,
        context: '_processTuyaNotification',
        showUserMessage: false,
      );
    }
  }
  
  /// Processa notificação Mibo
  Future<void> _processMiboNotification(TuyaNotification notification) async {
    try {
      final deviceInfo = _extractMiboDeviceInfo(notification);
      if (deviceInfo != null) {
        await _sendAlarmToEndpoint(deviceInfo, 'mibo');
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error, 
        stackTrace,
        context: '_processMiboNotification',
        showUserMessage: false,
      );
    }
  }
  
  /// Envia alarme para o endpoint com retry e timeout
  Future<bool> _sendAlarmToEndpoint(DeviceNotification deviceInfo, String source) async {
    try {
      // Enviar o alarme diretamente
      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          final response = await http.post(
            Uri.parse(_tuyaEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(deviceInfo.toJson()),
          ).timeout(_requestTimeout);
          
          if (response.statusCode == 200) {
            developer.log('✅ Alarme $source enviado com sucesso: ${deviceInfo.deviceId}', name: _tag);
            _logError(
              '✅ Alarme enviado com sucesso',
              '${deviceInfo.deviceId} - ${deviceInfo.message}',
              'success'
            );
            return true;
          } else {
            // Registrar erro específico
            final errorMessage = 'Erro HTTP ${response.statusCode}';
            final errorDetails = response.body;
            
            _logError(
              errorMessage,
              '${deviceInfo.deviceId}: $errorDetails',
              'error'
            );
            
            developer.log('❌ Erro HTTP $source: ${response.statusCode} - ${response.body}', name: _tag);
          }
        } catch (error, stackTrace) {
          developer.log('❌ Tentativa $attempt falhou para $source: $error', name: _tag);
          
          if (attempt == _maxRetries) {
            _logError(
              '❌ Falha ao enviar alarme',
              '${deviceInfo.deviceId}: $error',
              'error'
            );
            
            ErrorHandler.handleError(
              error, 
              stackTrace,
              context: '_sendAlarmToEndpoint ($source)',
              showUserMessage: false,
            );
          } else {
            // Aguardar antes da próxima tentativa
            await Future.delayed(Duration(seconds: attempt * 2));
          }
        }
      }
    } catch (error, stackTrace) {
      _logError(
        '❌ Erro crítico',
        '${deviceInfo.deviceId}: $error',
        'critical'
      );
      
      ErrorHandler.handleError(
        error, 
        stackTrace,
        context: '_sendAlarmToEndpoint ($source)',
        showUserMessage: false,
      );
    }
    return false;
  }
  
  /// Registra log de erro para exibição na interface
  void _logError(String message, String details, String type) {
    final logEntry = LogEntry(
      timestamp: DateTime.now(),
      message: message,
      details: details,
      type: type,
    );
    
    // Adicionar ao stream de logs
    _logController.add(logEntry);
    
    developer.log('📝 LOG [$type]: $message - $details', name: _tag);
  }
  
  /// Limpa notificações antigas do sistema Android
  void _cleanupOldNotifications() {
    try {
      // Limpar cache interno
      if (_processedNotifications.length > 50) {
        final keysToRemove = _processedNotifications.take(_processedNotifications.length - 50);
        _processedNotifications.removeAll(keysToRemove);
        developer.log('🧹 Cache limpo: ${keysToRemove.length} entradas removidas', name: _tag);
      }
      
      // Log de limpeza
      _logError(
        '🧹 Limpeza automática executada',
        'Cache reduzido para ${_processedNotifications.length} entradas',
        'info'
      );
    } catch (error, stackTrace) {
      developer.log('❌ Erro na limpeza automática: $error', name: _tag);
    }
  }
  
  /// Verifica se é notificação Tuya
  bool _isTuyaNotification(TuyaNotification notification) {
    final packageName = notification.packageName.toLowerCase();
    return packageName.contains('tuya') || 
           packageName.contains('smartlife') || 
           packageName.contains('smart') ||
           packageName.contains('home') ||
           packageName.contains('iot');
  }
  
  /// Verifica se é notificação Mibo
  bool _isMiboNotification(TuyaNotification notification) {
    return notification.packageName == 'br.com.intelbras.mibocam';
  }
  
  /// Extrai informações Tuya de forma segura
  DeviceNotification? _extractTuyaDeviceInfo(TuyaNotification notification) {
    try {
      String deviceId = '';
      String type = 'door';
      String message = '';
      
      if (notification.title.isNotEmpty) {
        if (notification.title.contains('Closing reminder') || 
            notification.title.contains('Door Alarm')) {
          final textParts = notification.text.split(' ');
          if (textParts.isNotEmpty) {
            deviceId = textParts[0];
          }
        } else {
          deviceId = notification.title;
        }
      }
      
      if (notification.title.toLowerCase().contains('door') ||
          notification.title.toLowerCase().contains('closing') ||
          notification.title.toLowerCase().contains('opened')) {
        type = 'door';
      } else if (notification.title.toLowerCase().contains('motion') ||
                 notification.title.toLowerCase().contains('movimento')) {
        type = 'motion';
      }
      
      message = notification.text.isNotEmpty ? notification.text : notification.title;
      
      if (deviceId.isNotEmpty) {
        return DeviceNotification(
          deviceId: deviceId,
          type: type,
          message: message,
          timestamp: notification.date,
          source: 'tuya',
        );
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error, 
        stackTrace,
        context: '_extractTuyaDeviceInfo',
        showUserMessage: false,
      );
    }
    return null;
  }
  
  /// Extrai informações Mibo de forma segura
  DeviceNotification? _extractMiboDeviceInfo(TuyaNotification notification) {
    try {
      String deviceId = '';
      String message = '';
      
      if (notification.text.isNotEmpty) {
        final lines = notification.text.split('\n');
        if (lines.length >= 2) {
          deviceId = lines[0].trim();
          message = lines[1].trim();
        } else if (lines.length == 1) {
          message = lines[0].trim();
          deviceId = notification.title.isNotEmpty ? notification.title : 'Detecção de movimento';
        } else {
          deviceId = notification.text.trim();
          message = notification.title.isNotEmpty ? notification.title : 'Detecção de movimento';
        }
      } else {
        deviceId = notification.title.isNotEmpty ? notification.title : 'Unknown Device';
        message = 'Detecção de movimento';
      }
      
      if (deviceId.isNotEmpty && deviceId != 'Unknown Device') {
        return DeviceNotification(
          deviceId: deviceId,
          type: 'motion',
          message: message,
          timestamp: notification.date,
          source: 'mibo',
        );
      }
    } catch (error, stackTrace) {
      ErrorHandler.handleError(
        error, 
        stackTrace,
        context: '_extractMiboDeviceInfo',
        showUserMessage: false,
      );
    }
    return null;
  }
  
  /// Adiciona notificação ao cache com limpeza automática
  void _addToCache(String key) {
    _processedNotifications.add(key);
    
    // Limpar cache se ficar muito grande
    if (_processedNotifications.length > _maxCacheSize) {
      final keysToRemove = _processedNotifications.take(_processedNotifications.length - _maxCacheSize);
      _processedNotifications.removeAll(keysToRemove);
    }
  }
  
  /// Limpa o cache manualmente
  void clearCache() {
    _processedNotifications.clear();
  }
  
  /// Obtém estatísticas do cache
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _processedNotifications.length,
      'maxCacheSize': _maxCacheSize,
    };
  }
  
  /// Dispose dos controllers
  void dispose() {
    _tuyaController.close();
    _miboController.close();
    _allController.close();
    _processedNotifications.clear();
  }
}
