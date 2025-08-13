import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // Added for jsonDecode
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'screens/logs_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ERB Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberPassword = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Carrega as credenciais salvas do SharedPreferences
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('saved_username') ?? '';
      final savedPassword = prefs.getString('saved_password') ?? '';
      final rememberPassword = prefs.getBool('remember_password') ?? false;

      setState(() {
        _emailController.text = savedUsername;
        _passwordController.text = savedPassword;
        _rememberPassword = rememberPassword;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar credenciais salvas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Salva as credenciais no SharedPreferences
  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_rememberPassword) {
        await prefs.setString('saved_username', _emailController.text);
        await prefs.setString('saved_password', _passwordController.text);
        await prefs.setBool('remember_password', true);
      } else {
        // Remove as credenciais salvas se não quiser lembrar
        await prefs.remove('saved_username');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_password', false);
      }
    } catch (e) {
      print('Erro ao salvar credenciais: $e');
    }
  }

  void _handleLogin() async {
    // Validação com credenciais fixas
    if (_emailController.text == 'auttec' && _passwordController.text == 'auttec2025') {
      // Salvar credenciais se marcou "lembrar senha"
      await _saveCredentials();
      
      // Navegar para a tela home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Mostrar mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credenciais inválidas! Use: auttec / auttec2025'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ERB Monitor - Login'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ERB Monitor
            const Text(
              'ERB Monitor',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Bem-vindo ao ERB Monitor',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            
            // Campo de usuário
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Usuário',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
                hintText: 'Digite: auttec',
                suffixIcon: _emailController.text.isNotEmpty && _rememberPassword
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            
            // Campo de senha
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                hintText: 'Digite: auttec2025',
                suffixIcon: _passwordController.text.isNotEmpty && _rememberPassword
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : null,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            
            // Checkbox "Lembrar senha"
            Row(
              children: [
                Checkbox(
                  value: _rememberPassword,
                  onChanged: (value) {
                    setState(() {
                      _rememberPassword = value ?? false;
                    });
                  },
                ),
                const Text(
                  'Lembrar senha',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                // Botão para limpar credenciais salvas
                if (_emailController.text.isNotEmpty || _passwordController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () async {
                      // Limpar campos
                      setState(() {
                        _emailController.clear();
                        _passwordController.clear();
                        _rememberPassword = false;
                      });
                      
                      // Remover credenciais salvas
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('saved_username');
                        await prefs.remove('saved_password');
                        await prefs.setBool('remember_password', false);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Credenciais limpas com sucesso'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        print('Erro ao limpar credenciais: $e');
                      }
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Limpar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Botão de login
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const platform = MethodChannel('com.example.erb_monitor/sms');
  static const notificationChannel = EventChannel('com.example.erb_monitor/notifications');
  
  List<SmsMessage> _smsMessages = [];
  List<TuyaNotification> _tuyaNotifications = [];
  List<TuyaNotification> _allNotifications = []; // Todas as notificações capturadas
  List<TuyaNotification> _miboNotifications = []; // Notificações do Mibo de câmeras
  bool _isLoading = true;
  bool _hasPermission = false;
  int _currentIndex = 0;
  bool _isBackgroundServiceRunning = true; // Status do serviço em background
  int _lastClearedCount = 0; // Contador de notificações limpas na última operação



  /// Chama o endpoint para câmeras Mibo
  Future<void> _callMiboAlarmEndpoint(DeviceNotification deviceInfo) async {
    try {
      const String endpoint = 'https://mvaqkxfptgkudqbvuxer.supabase.co/functions/v1/create-alarm';
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "device_id": deviceInfo.deviceId,
          "type": "motion",
          "message": deviceInfo.message,
          "active": deviceInfo.active,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Alarme Mibo enviado com sucesso para: ${deviceInfo.deviceId}');
        print('📊 Resposta: ${response.body}');
      } else {
        print('❌ Erro ao enviar alarme Mibo: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Erro na chamada HTTP Mibo: $e');
    }
  }

  /// Chama o endpoint para sensores Tuya
  Future<void> _callTuyaAlarmEndpoint(DeviceNotification deviceInfo) async {
    try {
      const String endpoint = 'https://mvaqkxfptgkudqbvuxer.supabase.co/functions/v1/create-alarm';
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "device_id": deviceInfo.deviceId,
          "type": deviceInfo.type,
          "message": deviceInfo.message,
          "active": deviceInfo.active,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Alarme Tuya enviado com sucesso para: ${deviceInfo.deviceId}');
        print('📊 Resposta: ${response.body}');
      } else {
        print('❌ Erro ao enviar alarme Tuya: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Erro na chamada HTTP Tuya: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _listenToNotifications();
    // Não verificar status do serviço automaticamente
    // _checkBackgroundServiceStatus();
    // Removido _loadHistoricalNotifications() pois agora capturamos em tempo real
  }

  void _listenToNotifications() {
    notificationChannel.receiveBroadcastStream().listen((dynamic event) {
      try {
        final notification = TuyaNotification.fromJson(event.toString());
        
        setState(() {
          _allNotifications.insert(0, notification);
          
          // Filtrar notificações Tuya
          if (notification.packageName.toLowerCase().contains('tuya') ||
              notification.title.toLowerCase().contains('tuya') ||
              notification.text.toLowerCase().contains('tuya')) {
            _tuyaNotifications.insert(0, notification);
            
            // Chamar endpoint para sensores Tuya
            final deviceInfo = _extractTuyaDeviceInfo(notification);
            if (deviceInfo != null) {
              _callTuyaAlarmEndpoint(deviceInfo);
            }
          }
          
          // Filtrar notificações do Mibo de câmeras
          if (notification.packageName == 'br.com.intelbras.mibocam') {
            _miboNotifications.insert(0, notification);
            print('📹 Notificação Mibo capturada: ${notification.title} - ${notification.text}');
            
            // Chamar endpoint para câmeras Mibo
            final deviceInfo = _extractMiboDeviceInfo(notification);
            if (deviceInfo != null) {
              _callMiboAlarmEndpoint(deviceInfo);
            }
          }
          
          // Limitar o número de notificações para performance
          if (_allNotifications.length > 100) {
            _allNotifications.removeRange(100, _allNotifications.length);
          }
          if (_tuyaNotifications.length > 50) {
            _tuyaNotifications.removeRange(50, _tuyaNotifications.length);
          }
          if (_miboNotifications.length > 50) {
            _miboNotifications.removeRange(50, _miboNotifications.length);
          }
        });
        
        print('📱 Notificação ignorada (não é Tuya): ${notification.packageName} - ${notification.title}');
      } catch (e) {
        print('❌ Erro ao processar notificação: $e');
      }
    }, onError: (error) {
      print('❌ Erro no canal de notificações: $error');
    });
  }
  
  bool _isTuyaNotification(TuyaNotification notification) {
    final packageName = notification.packageName.toLowerCase();
    return packageName.contains('tuya') || 
           packageName.contains('smartlife') || 
           packageName.contains('smart') ||
           packageName.contains('home') ||
           packageName.contains('iot');
  }

  /// Extrai informações padronizadas de uma notificação Tuya
  DeviceNotification? _extractTuyaDeviceInfo(TuyaNotification notification) {
    try {
      String deviceId = '';
      String type = 'door';
      String message = '';
      
      // Extrair device_id do título ou texto
      if (notification.title.isNotEmpty) {
        // Padrão: "Closing reminder:" ou "Door Alarm"
        if (notification.title.contains('Closing reminder') || 
            notification.title.contains('Door Alarm')) {
          // O device_id está no texto, geralmente é a primeira palavra
          final textParts = notification.text.split(' ');
          if (textParts.isNotEmpty) {
            deviceId = textParts[0];
          }
        } else {
          // Se o título não for padrão, usar como device_id
          deviceId = notification.title;
        }
      }
      
      // Determinar o tipo baseado no conteúdo
      if (notification.title.toLowerCase().contains('door') ||
          notification.title.toLowerCase().contains('closing') ||
          notification.title.toLowerCase().contains('opened')) {
        type = 'door';
      } else if (notification.title.toLowerCase().contains('motion') ||
                 notification.title.toLowerCase().contains('movimento')) {
        type = 'motion';
      }
      
      // Usar o texto completo como mensagem
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
    } catch (e) {
      print('❌ Erro ao extrair informações Tuya: $e');
    }
    return null;
  }
  
  /// Extrai informações padronizadas de uma notificação Mibo
  DeviceNotification? _extractMiboDeviceInfo(TuyaNotification notification) {
    try {
      String deviceId = '';
      String type = 'motion';
      String message = '';
      
      // Para Mibo, o device_id está na segunda linha do texto
      if (notification.text.isNotEmpty) {
        final lines = notification.text.split('\n');
        if (lines.length >= 2) {
          print('Primeira linha: mensagem (ex: "Detecção de movimento")');
          // Primeira linha: mensagem (ex: "Detecção de movimento")
          deviceId = lines[0].trim();
          // Segunda linha: device_id (ex: "iM5-SC-1814")
          message = lines[1].trim();
        } else if (lines.length == 1) {
          print('Segunda linha: device_id (ex: "iM5-SC-1814")');
          // Se só tem uma linha, usar como device_id
          message = lines[0].trim();
          deviceId = notification.title.isNotEmpty ? notification.title : 'Detecção de movimento';
        } else {
          print('Fallback: device_id (ex: "iM5-SC-1814")');
          // Fallback
          deviceId = notification.text.trim();
          message = notification.title.isNotEmpty ? notification.title : 'Detecção de movimento';
        }
      } else {
        // Se não tem texto, usar título como device_id
        deviceId = notification.title.isNotEmpty ? notification.title : 'Unknown Device';
        message = 'Detecção de movimento';
      }
      
      // Mibo é sempre motion
      type = 'motion';
      
      // Garantir que temos pelo menos um device_id válido
      if (deviceId.isNotEmpty && deviceId != 'Unknown Device') {
        return DeviceNotification(
          deviceId: deviceId, // Device ID correto (ex: iM5-SC-1814)
          type: type,
          message: message, // Mensagem correta (ex: Detecção de movimento)
          timestamp: notification.date,
          source: 'mibo',
        );
      }
    } catch (e) {
      print('❌ Erro ao extrair informações Mibo: $e');
    }
    return null;
  }

  Future<void> _requestPermissions() async {
    // Solicitar permissões
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.phone,
      Permission.notification,
    ].request();

    if (statuses[Permission.sms] == PermissionStatus.granted &&
        statuses[Permission.phone] == PermissionStatus.granted) {
      setState(() {
        _hasPermission = true;
      });
      _loadSmsMessages();
    } else {
      setState(() {
        _hasPermission = false;
      });
    }
  }

  Future<void> _openNotificationSettings() async {
    try {
      // Tentar abrir diretamente as configurações de Notification Listener
      await openAppSettings();
    } catch (e) {
      print('Erro ao abrir configurações: $e');
    }
  }

  Future<void> _openNotificationListenerSettings() async {
    try {
      // Abrir configurações específicas de Notification Listener
      await openAppSettings();
      
      // Mostrar instruções específicas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vá em: Configurações > Apps > ERB Monitor > Notificações > Acesso às notificações'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      print('Erro ao abrir configurações de Notification Listener: $e');
    }
  }
  
  Future<void> _clearSystemNotifications() async {
    try {
      // Mostrar indicador de carregamento
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧹 Limpando notificações do sistema...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      final result = await platform.invokeMethod('clearSystemNotifications');
      
      if (result == true) {
        // Mostrar mensagem de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Notificações do sistema limpas com sucesso!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        // Atualizar a interface se necessário
        setState(() {
          // Capturar o número de notificações antes de limpar
          final totalNotifications = _tuyaNotifications.length + _miboNotifications.length + _allNotifications.length;
          
          // Limpar notificações locais também
          _tuyaNotifications.clear();
          _miboNotifications.clear();
          _allNotifications.clear();
          
          // Atualizar contador de notificações limpas
          _lastClearedCount = totalNotifications;
        });
        
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Não foi possível limpar as notificações'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao limpar notificações do sistema: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao limpar notificações: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _checkNotificationAccess() async {
    try {
      // Verificar se o app tem acesso às notificações
      final result = await platform.invokeMethod('checkNotificationAccess');
      print('Status do acesso às notificações: $result');
      
      if (result == true) {
        // Acesso ativo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Acesso às notificações ativo'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Acesso negado - mostrar instruções específicas
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Acesso às Notificações Negado'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Para ativar o acesso às notificações:'),
                SizedBox(height: 8),
                Text('1. Vá em Configurações > Sistema'),
                Text('2. Toque em "Acesso às notificações"'),
                Text('3. Procure por "ERB Monitor"'),
                Text('4. Ative o toggle ao lado do app'),
                SizedBox(height: 8),
                Text('Ou:'),
                Text('1. Configurações > Apps > ERB Monitor'),
                Text('2. Notificações > Acesso às notificações'),
                Text('3. Ative o toggle'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openNotificationListenerSettings();
                },
                child: const Text('Abrir Configurações'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Erro ao verificar acesso às notificações: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao verificar acesso: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _loadSmsMessages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Tentar ler SMS reais primeiro
      List<SmsMessage> realMessages = await _getRealSmsMessages();
      
      if (realMessages.isNotEmpty) {
        setState(() {
          _smsMessages = realMessages;
          _isLoading = false;
        });
      } else {
        // Se não conseguir ler SMS reais, usar dados de exemplo
        await Future.delayed(const Duration(seconds: 1));
        List<SmsMessage> exampleMessages = _getExampleMessages();
        
        setState(() {
          _smsMessages = exampleMessages;
          _isLoading = false;
        });
        
        // Mostrar aviso de que são dados de exemplo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exibindo dados de exemplo. SMS reais não foram encontrados.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Erro ao carregar mensagens: $e');
    }
  }

  Future<List<SmsMessage>> _getRealSmsMessages() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getSmsMessages');
      return result.map((data) => SmsMessage.fromMap(Map<String, dynamic>.from(data))).toList();
    } catch (e) {
      print('Erro ao ler SMS reais: $e');
      return [];
    }
  }

  List<SmsMessage> _getExampleMessages() {
    return [
      SmsMessage(
        id: '1',
        address: '+55 11 99999-0001',
        body: 'ERB-001: ALERTA CRÍTICO - Temperatura elevada detectada: 85°C. Ação imediata necessária.',
        date: DateTime.now().subtract(const Duration(minutes: 2)),
        type: 'inbox',
      ),
      SmsMessage(
        id: '2',
        address: '+55 21 99999-0002',
        body: 'ERB-015: ATENÇÃO - Sistema operando com bateria de backup. Verificar fonte de energia.',
        date: DateTime.now().subtract(const Duration(minutes: 5)),
        type: 'inbox',
      ),
      SmsMessage(
        id: '3',
        address: '+55 31 99999-0003',
        body: 'ERB-023: INFO - Manutenção programada iniciada. Sistema em modo de manutenção.',
        date: DateTime.now().subtract(const Duration(minutes: 8)),
        type: 'inbox',
      ),
      SmsMessage(
        id: '4',
        address: '+55 71 99999-0004',
        body: 'ERB-007: ATENÇÃO - Sinal fraco detectado. Intensidade abaixo do normal.',
        date: DateTime.now().subtract(const Duration(minutes: 12)),
        type: 'inbox',
      ),
      SmsMessage(
        id: '5',
        address: '+55 85 99999-0005',
        body: 'ERB-034: SUCESSO - Conexão restaurada com servidor principal. Sistema operacional.',
        date: DateTime.now().subtract(const Duration(minutes: 15)),
        type: 'inbox',
      ),
      SmsMessage(
        id: '6',
        address: '+55 81 99999-0006',
        body: 'ERB-012: ALERTA CRÍTICO - Falha de hardware detectada no módulo de transmissão.',
        date: DateTime.now().subtract(const Duration(minutes: 20)),
        type: 'inbox',
      ),
    ];
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permissão Necessária'),
        content: const Text(
          'Este aplicativo precisa de permissão para ler SMS para exibir as mensagens de alarme. '
          'Por favor, conceda as permissões necessárias.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _requestPermissions();
            },
            child: const Text('Tentar Novamente'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  AlarmSeverity _getSeverityFromSms(SmsMessage sms) {
    String body = sms.body?.toLowerCase() ?? '';
    
    if (body.contains('crítico') || body.contains('critico') || 
        body.contains('falha') || body.contains('erro') || 
        body.contains('emergência') || body.contains('emergencia') ||
        body.contains('alerta crítico')) {
      return AlarmSeverity.critical;
    } else if (body.contains('atenção') || body.contains('atencao') || 
               body.contains('aviso') || body.contains('warning')) {
      return AlarmSeverity.warning;
    } else if (body.contains('sucesso') || body.contains('ok') || 
               body.contains('restaurado') || body.contains('conectado')) {
      return AlarmSeverity.success;
    } else {
      return AlarmSeverity.info;
    }
  }

  AlarmSeverity _getSeverityFromTuyaNotification(TuyaNotification notification) {
    String title = notification.title.toLowerCase();
    String text = notification.text.toLowerCase();
    
    if (title.contains('alerta') || title.contains('erro') || 
        text.contains('falha') || text.contains('erro') || 
        text.contains('offline') || text.contains('desconectado')) {
      return AlarmSeverity.critical;
    } else if (title.contains('aviso') || title.contains('atenção') || 
               text.contains('warning') || text.contains('atencao')) {
      return AlarmSeverity.warning;
    } else if (title.contains('conectado') || title.contains('online') || 
               text.contains('sucesso') || text.contains('conectado')) {
      return AlarmSeverity.success;
    } else {
      return AlarmSeverity.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ERB Monitor - Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _hasPermission ? _loadSmsMessages : null,
            tooltip: 'Atualizar SMS',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: _checkNotificationAccess,
            tooltip: 'Verificar Notificações',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openNotificationListenerSettings,
            tooltip: 'Configurar Notificações',
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton.icon(
              onPressed: _clearSystemNotifications,
              icon: const Icon(Icons.cleaning_services, size: 18),
              label: const Text('Limpar', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          // Botão para controlar o serviço em background
          IconButton(
            icon: Icon(
              _isBackgroundServiceRunning ? Icons.stop_circle : Icons.play_circle,
              color: _isBackgroundServiceRunning ? Colors.red : Colors.green,
            ),
            onPressed: _isBackgroundServiceRunning 
                ? _stopBackgroundService 
                : _startBackgroundService,
            tooltip: _isBackgroundServiceRunning 
                ? 'Parar Serviço em Background' 
                : 'Iniciar Serviço em Background',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            tooltip: 'Sair',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
              ? _buildPermissionDeniedView()
              : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Status do serviço em background
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isBackgroundServiceRunning ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isBackgroundServiceRunning ? Colors.green[200]! : Colors.red[200]!,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _isBackgroundServiceRunning ? Icons.check_circle : Icons.error,
                    color: _isBackgroundServiceRunning ? Colors.green[600] : Colors.red[600],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isBackgroundServiceRunning 
                              ? 'Serviço em Background Ativo' 
                              : 'Serviço em Background Parado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isBackgroundServiceRunning ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                        Text(
                          _isBackgroundServiceRunning 
                              ? 'Monitorando notificações em tempo real' 
                              : 'Clique no botão play para iniciar',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isBackgroundServiceRunning ? Colors.green[600] : Colors.red[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isBackgroundServiceRunning 
                        ? _stopBackgroundService 
                        : _startBackgroundService,
                    icon: Icon(
                      _isBackgroundServiceRunning ? Icons.stop_circle : Icons.play_circle,
                      color: _isBackgroundServiceRunning ? Colors.red[600] : Colors.green[600],
                      size: 28,
                    ),
                    tooltip: _isBackgroundServiceRunning 
                        ? 'Parar Serviço' 
                        : 'Iniciar Serviço',
                  ),
                ],
              ),
              // Indicador de notificações limpas
              if (_lastClearedCount > 0)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cleaning_services,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Última limpeza: $_lastClearedCount notificações removidas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        
        // Tab bar
        Container(
          color: Colors.grey[100],
          child: Row(
            children: [
              _buildTab(0, 'SMS', Icons.sms),
              _buildTab(1, 'Tuya', Icons.smart_toy),
              _buildTab(2, 'Mibo Câmeras', Icons.videocam),
              _buildTab(3, 'Todas', Icons.list),
              _buildTab(4, 'Logs', Icons.assignment),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildSmsListView(),
              _buildTuyaListView(),
              _buildMiboListView(),
              _buildGeneralListView(),
              _buildLogsView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blue : Colors.grey[300]!,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sms_failed,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Permissão de SMS Negada',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este aplicativo precisa de permissão para ler SMS',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _requestPermissions,
            child: const Text('Conceder Permissão'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _openNotificationSettings,
            child: const Text('Configurar Notificações'),
          ),
        ],
      ),
    );
  }

  Widget _buildSmsListView() {
    if (_smsMessages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sms,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum SMS encontrado',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header com estatísticas
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard('Total SMS', '${_smsMessages.length}', Colors.blue),
              _buildStatCard('Críticos', 
                '${_smsMessages.where((sms) => _getSeverityFromSms(sms) == AlarmSeverity.critical).length}', 
                Colors.red),
              _buildStatCard('Atenção', 
                '${_smsMessages.where((sms) => _getSeverityFromSms(sms) == AlarmSeverity.warning).length}', 
                Colors.orange),
              _buildStatCard('Info', 
                '${_smsMessages.where((sms) => _getSeverityFromSms(sms) == AlarmSeverity.info).length}', 
                Colors.green),
            ],
          ),
        ),
        
        // Lista de SMS
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _smsMessages.length,
            itemBuilder: (context, index) {
              final sms = _smsMessages[index];
              return _buildSmsCard(sms);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTuyaListView() {
    if (_tuyaNotifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.smart_toy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aguardando notificações Tuya...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Para capturar notificações:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '1. Toque no botão ⚙️ (Configurações) na AppBar\n'
              '2. Vá em "Notificações" > "Acesso às notificações"\n'
              '3. Ative o toggle para "ERB Monitor"\n'
              '4. Gere notificações de qualquer app\n'
              '5. Apenas notificações Tuya serão exibidas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header com estatísticas
                            Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard('Tuya', '${_tuyaNotifications.length}', Colors.purple),
                              _buildStatCard('Capturadas', '${_allNotifications.length}', Colors.blue),
                              _buildStatCard('Críticos', 
                                '${_tuyaNotifications.where((notif) => _getSeverityFromTuyaNotification(notif) == AlarmSeverity.critical).length}', 
                                Colors.red),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard('Atenção', 
                                '${_tuyaNotifications.where((notif) => _getSeverityFromTuyaNotification(notif) == AlarmSeverity.warning).length}', 
                                Colors.orange),
                              _buildStatCard('Info', 
                                '${_tuyaNotifications.where((notif) => _getSeverityFromTuyaNotification(notif) == AlarmSeverity.info).length}', 
                                Colors.green),
                              _buildStatCard('Sucesso', 
                                '${_tuyaNotifications.where((notif) => _getSeverityFromTuyaNotification(notif) == AlarmSeverity.success).length}', 
                                Colors.green),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              const SizedBox(width: 8),
                              const Text(
                                'Capturando notificações em tempo real',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
        
        // Lista de notificações Tuya
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _tuyaNotifications.length,
            itemBuilder: (context, index) {
              final notification = _tuyaNotifications[index];
              return _buildTuyaCard(notification);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiboListView() {
    if (_miboNotifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aguardando notificações do Mibo...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Para capturar notificações:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '1. Toque no botão ⚙️ (Configurações) na AppBar\n'
              '2. Vá em "Notificações" > "Acesso às notificações"\n'
              '3. Ative o toggle para "ERB Monitor"\n'
              '4. Gere notificações de qualquer app\n'
              '5. Apenas notificações do Mibo serão exibidas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header com estatísticas
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Mibo', '${_miboNotifications.length}', Colors.teal),
                  _buildStatCard('Capturadas', '${_allNotifications.length}', Colors.blue),
                  _buildStatCard('Críticos', 
                    '${_miboNotifications.where((notif) => _getSeverityFromTuyaNotification(notif) == AlarmSeverity.critical).length}', 
                    Colors.red),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Atenção', 
                    '${_miboNotifications.where((notif) => _getSeverityFromTuyaNotification(notif) == AlarmSeverity.warning).length}', 
                    Colors.orange),
                  _buildStatCard('Info', 
                    '${_miboNotifications.where((notif) => _getSeverityFromTuyaNotification(notif) == AlarmSeverity.info).length}', 
                    Colors.green),
                  _buildStatCard('Sucesso', 
                    '${_miboNotifications.where((notif) => _getSeverityFromTuyaNotification(notif) == AlarmSeverity.success).length}', 
                    Colors.green),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Capturando notificações em tempo real',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Lista de notificações do Mibo
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _miboNotifications.length,
            itemBuilder: (context, index) {
              final notification = _miboNotifications[index];
              return _buildTuyaCard(notification); // Reutiliza _buildTuyaCard
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogsView() {
    return const LogsScreen();
  }

  Widget _buildGeneralListView() {
    if (_allNotifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aguardando notificações gerais...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Para capturar notificações:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '1. Toque no botão ⚙️ (Configurações) na AppBar\n'
              '2. Vá em "Notificações" > "Acesso às notificações"\n'
              '3. Ative o toggle para "ERB Monitor"\n'
              '4. Gere notificações de qualquer app\n'
              '5. Todas as notificações serão exibidas aqui',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header com estatísticas
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Total', '${_allNotifications.length}', Colors.blue),
                  _buildStatCard('Tuya', '${_tuyaNotifications.length}', Colors.purple),
                  _buildStatCard('Mibo', '${_miboNotifications.length}', Colors.teal),
                  _buildStatCard('Outros', '${_allNotifications.length - _tuyaNotifications.length - _miboNotifications.length}', Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Todas as notificações capturadas em tempo real',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Lista de todas as notificações
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _allNotifications.length,
            itemBuilder: (context, index) {
              final notification = _allNotifications[index];
              return _buildGeneralCard(notification);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSmsCard(SmsMessage sms) {
    final severity = _getSeverityFromSms(sms);
    Color cardColor;
    IconData severityIcon;
    
    switch (severity) {
      case AlarmSeverity.critical:
        cardColor = Colors.red[50]!;
        severityIcon = Icons.error;
        break;
      case AlarmSeverity.warning:
        cardColor = Colors.orange[50]!;
        severityIcon = Icons.warning;
        break;
      case AlarmSeverity.info:
        cardColor = Colors.blue[50]!;
        severityIcon = Icons.info;
        break;
      case AlarmSeverity.success:
        cardColor = Colors.green[50]!;
        severityIcon = Icons.check_circle;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: cardColor,
      child: ListTile(
        leading: Icon(
          severityIcon,
          color: _getSeverityColor(severity),
          size: 32,
        ),
        title: Text(
          sms.address ?? 'Número Desconhecido',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              sms.body ?? 'Sem conteúdo',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(sms.date ?? DateTime.now()),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          _showSmsDetails(sms);
        },
      ),
    );
  }

  Widget _buildTuyaCard(TuyaNotification notification) {
    final severity = _getSeverityFromTuyaNotification(notification);
    Color cardColor;
    IconData severityIcon;
    
    // Extrair informações padronizadas
    DeviceNotification? deviceInfo;
    if (notification.packageName == 'br.com.intelbras.mibocam') {
      deviceInfo = _extractMiboDeviceInfo(notification);
    } else if (notification.packageName.toLowerCase().contains('tuya')) {
      deviceInfo = _extractTuyaDeviceInfo(notification);
    }
    
    switch (severity) {
      case AlarmSeverity.critical:
        cardColor = Colors.red[50]!;
        severityIcon = Icons.error;
        break;
      case AlarmSeverity.warning:
        cardColor = Colors.orange[50]!;
        severityIcon = Icons.warning;
        break;
      case AlarmSeverity.info:
        cardColor = Colors.blue[50]!;
        severityIcon = Icons.info;
        break;
      case AlarmSeverity.success:
        cardColor = Colors.green[50]!;
        severityIcon = Icons.check_circle;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ícone e timestamp
            Row(
              children: [
                Icon(
                  severityIcon,
                  color: _getSeverityColor(severity),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceInfo?.source == 'mibo' ? '📹 Mibo Camera' : '🏠 Tuya Device',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        _formatTimestamp(notification.date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botão para copiar JSON
                IconButton(
                  onPressed: () {
                    if (deviceInfo != null) {
                      final json = deviceInfo!.toJson();
                      // Aqui você pode implementar a cópia para clipboard
                      print('📋 JSON copiado: $json');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('JSON copiado: ${json.toString()}'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copiar JSON',
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informações padronizadas
            if (deviceInfo != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Device ID', deviceInfo!.deviceId, Icons.devices),
                    _buildInfoRow('Type', deviceInfo.type, Icons.category),
                    _buildInfoRow('Message', deviceInfo.message, Icons.message),
                    _buildInfoRow('Active', deviceInfo.active.toString(), Icons.check_circle),
                  ],
                ),
              ),
            ] else ...[
              // Fallback para notificações não processadas
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Title', notification.title, Icons.title),
                    _buildInfoRow('Text', notification.text, Icons.text_fields),
                    _buildInfoRow('Package', notification.packageName, Icons.apps),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(AlarmSeverity severity) {
    switch (severity) {
      case AlarmSeverity.critical:
        return Colors.red;
      case AlarmSeverity.warning:
        return Colors.orange;
      case AlarmSeverity.info:
        return Colors.blue;
      case AlarmSeverity.success:
        return Colors.green;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else {
      return '${difference.inDays}d atrás';
    }
  }

  void _showSmsDetails(SmsMessage sms) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(sms.address ?? 'SMS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sms.body ?? 'Sem conteúdo'),
            const SizedBox(height: 16),
            Text('De: ${sms.address ?? 'Desconhecido'}'),
            Text('Data: ${_formatTimestamp(sms.date ?? DateTime.now())}'),
            if (sms.date != null)
              Text('Horário: ${sms.date!.toString().substring(11, 19)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showTuyaDetails(TuyaNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.text),
            const SizedBox(height: 16),
            Text('App: ${notification.packageName}'),
            Text('Data: ${_formatTimestamp(notification.date)}'),
            Text('Horário: ${notification.date.toString().substring(11, 19)}'),
            if (notification.bigText.isNotEmpty)
              Text('Detalhes: ${notification.bigText}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralCard(TuyaNotification notification) {
    final isTuya = _isTuyaNotification(notification);
    final severity = _getSeverityFromTuyaNotification(notification);
    Color cardColor;
    IconData severityIcon;
    
    // Cores diferentes para Tuya vs outros apps
    if (isTuya) {
      switch (severity) {
        case AlarmSeverity.critical:
          cardColor = Colors.red[50]!;
          severityIcon = Icons.error;
          break;
        case AlarmSeverity.warning:
          cardColor = Colors.orange[50]!;
          severityIcon = Icons.warning;
          break;
        case AlarmSeverity.info:
          cardColor = Colors.blue[50]!;
          severityIcon = Icons.info;
          break;
        case AlarmSeverity.success:
          cardColor = Colors.green[50]!;
          severityIcon = Icons.check_circle;
          break;
      }
    } else {
      cardColor = Colors.grey[50]!;
      severityIcon = Icons.notifications;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: cardColor,
      child: ListTile(
        leading: Icon(
          severityIcon,
          color: isTuya ? _getSeverityColor(severity) : Colors.grey,
          size: 32,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isTuya ? Colors.purple : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isTuya ? 'TUYA' : 'GERAL',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.apps, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    notification.packageName,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatTimestamp(notification.date),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          _showGeneralDetails(notification);
        },
      ),
    );
  }

  void _showGeneralDetails(TuyaNotification notification) {
    final isTuya = _isTuyaNotification(notification);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(notification.title)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isTuya ? Colors.purple : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isTuya ? 'TUYA' : 'GERAL',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.text),
            const SizedBox(height: 16),
            Text('App: ${notification.packageName}'),
            Text('Data: ${_formatTimestamp(notification.date)}'),
            Text('Horário: ${notification.date.toString().substring(11, 19)}'),
            if (notification.bigText.isNotEmpty)
              Text('Detalhes: ${notification.bigText}'),
            if (notification.infoText.isNotEmpty)
              Text('Info: ${notification.infoText}'),
            if (notification.subText.isNotEmpty)
              Text('Sub: ${notification.subText}'),
            if (notification.summaryText.isNotEmpty)
              Text('Resumo: ${notification.summaryText}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Verifica o status do serviço em background
  Future<void> _checkBackgroundServiceStatus() async {
    try {
      // Por padrão, assumimos que está rodando
      setState(() {
        _isBackgroundServiceRunning = true;
      });
    } catch (e) {
      print('Erro ao verificar status do serviço: $e');
    }
  }
  
  /// Inicia o serviço em background
  Future<void> _startBackgroundService() async {
    try {
      final result = await platform.invokeMethod('startBackgroundService');
      if (result == true) {
        setState(() {
          _isBackgroundServiceRunning = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Serviço em background iniciado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erro ao iniciar serviço: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao iniciar serviço: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Para o serviço em background
  Future<void> _stopBackgroundService() async {
    try {
      final result = await platform.invokeMethod('stopBackgroundService');
      if (result == true) {
        setState(() {
          _isBackgroundServiceRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏹️ Serviço em background parado'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erro ao parar serviço: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao parar serviço: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

enum AlarmSeverity { critical, warning, info, success }

class DeviceNotification {
  final String deviceId;
  final String type;
  final String message;
  final bool active;
  final DateTime timestamp;
  final String source; // 'tuya' ou 'mibo'

  DeviceNotification({
    required this.deviceId,
    required this.type,
    required this.message,
    this.active = true,
    required this.timestamp,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      "device_id": deviceId,
      "type": type,
      "message": message,
      "active": active,
    };
  }
}

class SmsMessage {
  final String id;
  final String? address;
  final String? body;
  final DateTime? date;
  final String type;

  SmsMessage({
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
}

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

  TuyaNotification({
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
  });

  factory TuyaNotification.fromJson(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    
    return TuyaNotification(
      id: json['id']?.toString() ?? '',
      packageName: json['packageName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      bigText: json['bigText']?.toString() ?? '',
      infoText: json['infoText']?.toString() ?? '',
      subText: json['subText']?.toString() ?? '',
      summaryText: json['summaryText']?.toString() ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(json['postTime'] ?? DateTime.now().millisecondsSinceEpoch),
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>? ?? {},
    );
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
    };
  }
}
