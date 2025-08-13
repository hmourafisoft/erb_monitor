import 'dart:convert';

/// Modelo para entradas de log do sistema
class LogEntry {
  final DateTime timestamp;
  final String message;
  final String details;
  final String type; // 'success', 'error', 'warning', 'info', 'critical'

  const LogEntry({
    required this.timestamp,
    required this.message,
    required this.details,
    required this.type,
  });

  @override
  String toString() {
    return 'LogEntry(${timestamp.toString()}, $type: $message)';
  }
}

/// Modelo para notificações de dispositivos
class DeviceNotification {
  final String deviceId;
  final String type;
  final String message;
  final bool active;
  final DateTime timestamp;
  final String source; // 'tuya' ou 'mibo'

  const DeviceNotification({
    required this.deviceId,
    required this.type,
    required this.message,
    this.active = true,
    required this.timestamp,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'type': type,
      'message': message,
      'active': active,
    };
  }

  @override
  String toString() {
    return 'DeviceNotification(deviceId: $deviceId, type: $type, source: $source)';
  }
}

/// Modelo para mensagens SMS
class SmsMessage {
  final String id;
  final String? address;
  final String? body;
  final DateTime? date;
  final String type;

  const SmsMessage({
    required this.id,
    this.address,
    this.body,
    this.date,
    required this.type,
  });

  factory SmsMessage.fromMap(Map<String, dynamic> map) {
    return SmsMessage(
      id: map['id'] ?? '',
      address: map['address'],
      body: map['body'],
      date: map['date'] != null ? DateTime.fromMillisecondsSinceEpoch(map['date']) : null,
      type: map['type'] ?? 'inbox',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'body': body,
      'date': date?.millisecondsSinceEpoch,
      'type': type,
    };
  }

  @override
  String toString() {
    return 'SmsMessage(id: $id, address: $address, type: $type)';
  }
}

/// Modelo para notificações Tuya com parsing seguro
class TuyaNotification {
  final String id;
  final String packageName;
  final String title;
  final String text;
  final String bigText;
  final String infoText;
  final String subText;
  final String summaryText;
  final DateTime date;
  final Map<String, dynamic> additionalInfo;
  final int postTime; // Adicionado para compatibilidade

  const TuyaNotification({
    required this.id,
    required this.packageName,
    required this.title,
    required this.text,
    required this.bigText,
    required this.infoText,
    required this.subText,
    required this.summaryText,
    required this.date,
    required this.additionalInfo,
    required this.postTime,
  });

  /// Factory constructor com parsing seguro
  factory TuyaNotification.fromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // Extrair timestamp de forma segura
      DateTime timestamp;
      int postTime;
      try {
        final postTimeValue = json['postTime'];
        if (postTimeValue is int) {
          postTime = postTimeValue;
          timestamp = DateTime.fromMillisecondsSinceEpoch(postTimeValue);
        } else if (postTimeValue is String) {
          postTime = DateTime.tryParse(postTimeValue)?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
          timestamp = DateTime.fromMillisecondsSinceEpoch(postTime);
        } else {
          postTime = DateTime.now().millisecondsSinceEpoch;
          timestamp = DateTime.now();
        }
      } catch (e) {
        postTime = DateTime.now().millisecondsSinceEpoch;
        timestamp = DateTime.now();
      }
      
      return TuyaNotification(
        id: json['id']?.toString() ?? '',
        packageName: json['packageName']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        bigText: json['bigText']?.toString() ?? '',
        infoText: json['infoText']?.toString() ?? '',
        subText: json['subText']?.toString() ?? '',
        summaryText: json['summaryText']?.toString() ?? '',
        date: timestamp,
        additionalInfo: json['additionalInfo'] as Map<String, dynamic>? ?? {},
        postTime: postTime,
      );
    } catch (e) {
      // Retornar notificação vazia em caso de erro
      return TuyaNotification(
        id: '',
        packageName: '',
        title: '',
        text: '',
        bigText: '',
        infoText: '',
        subText: '',
        summaryText: '',
        date: DateTime.now(),
        additionalInfo: {},
        postTime: DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'packageName': packageName,
      'title': title,
      'text': text,
      'bigText': bigText,
      'infoText': infoText,
      'subText': subText,
      'summaryText': summaryText,
      'date': date.millisecondsSinceEpoch,
      'additionalInfo': additionalInfo,
      'postTime': postTime,
    };
  }

  @override
  String toString() {
    return 'TuyaNotification(id: $id, packageName: $packageName, title: $title)';
  }
}

/// Enum para severidade de alarmes
enum AlarmSeverity { 
  critical, 
  warning, 
  info, 
  success 
}

/// Extensões úteis para AlarmSeverity
extension AlarmSeverityExtension on AlarmSeverity {
  String get displayName {
    switch (this) {
      case AlarmSeverity.critical:
        return 'Crítico';
      case AlarmSeverity.warning:
        return 'Atenção';
      case AlarmSeverity.info:
        return 'Info';
      case AlarmSeverity.success:
        return 'Sucesso';
    }
  }
  
  int get priority {
    switch (this) {
      case AlarmSeverity.critical:
        return 4;
      case AlarmSeverity.warning:
        return 3;
      case AlarmSeverity.info:
        return 2;
      case AlarmSeverity.success:
        return 1;
    }
  }
}
