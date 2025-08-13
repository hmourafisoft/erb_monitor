package com.example.erb_monitor

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.ContentResolver
import android.database.Cursor
import android.net.Uri
import android.provider.Telephony
import org.json.JSONArray
import org.json.JSONObject
import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.StatusBarNotification
import android.util.Log
import java.util.concurrent.Executors
import java.util.concurrent.ThreadPoolExecutor

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.erb_monitor/sms"
    private val NOTIFICATION_CHANNEL = "com.example.erb_monitor/notifications"
    private val TAG = "MainActivity"
    
    // Executor para operações em background
    private val backgroundExecutor: ThreadPoolExecutor = Executors.newFixedThreadPool(2) as ThreadPoolExecutor

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "Configurando Flutter Engine")
        
        // Configurar canal de métodos
        setupMethodChannel(flutterEngine)
        
        // Configurar canal de eventos
        setupEventChannel(flutterEngine)
    }
    
    private fun setupMethodChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "getSmsMessages" -> {
                        Log.d(TAG, "Método getSmsMessages chamado")
                        backgroundExecutor.execute {
                            try {
                                val messages = getSmsMessages()
                                runOnUiThread {
                                    result.success(messages)
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Erro ao ler SMS", e)
                                runOnUiThread {
                                    result.error("SMS_READ_ERROR", "Erro ao ler SMS", e.message)
                                }
                            }
                        }
                    }
                    "checkNotificationAccess" -> {
                        Log.d(TAG, "Método checkNotificationAccess chamado")
                        try {
                            val hasAccess = checkNotificationAccess()
                            result.success(hasAccess)
                        } catch (e: Exception) {
                            Log.e(TAG, "Erro ao verificar acesso às notificações", e)
                            result.error("NOTIFICATION_ACCESS_ERROR", "Erro ao verificar acesso às notificações", e.message)
                        }
                    }
                    "startBackgroundService" -> {
                        Log.d(TAG, "Método startBackgroundService chamado")
                        try {
                            startNotificationService()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Erro ao iniciar serviço", e)
                            result.error("SERVICE_START_ERROR", "Erro ao iniciar serviço", e.message)
                        }
                    }
                    "stopBackgroundService" -> {
                        Log.d(TAG, "Método stopBackgroundService chamado")
                        try {
                            stopNotificationService()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Erro ao parar serviço", e)
                            result.error("SERVICE_STOP_ERROR", "Erro ao parar serviço", e.message)
                        }
                    }
                    "clearSystemNotifications" -> {
                        Log.d(TAG, "Método clearSystemNotifications chamado")
                        try {
                            clearSystemNotifications()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Erro ao limpar notificações", e)
                            result.error("CLEAR_ERROR", "Erro ao limpar notificações", e.message)
                        }
                    }
                    else -> {
                        Log.w(TAG, "Método não implementado: ${call.method}")
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Erro geral no MethodChannel", e)
                result.error("GENERAL_ERROR", "Erro geral", e.message)
            }
        }
    }
    
    private fun setupEventChannel(flutterEngine: FlutterEngine) {
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    Log.d(TAG, "EventChannel: onListen chamado")
                    try {
                        NotificationService.setEventSink(events)
                    } catch (e: Exception) {
                        Log.e(TAG, "Erro ao configurar EventSink", e)
                    }
                }
                
                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "EventChannel: onCancel chamado")
                    try {
                        NotificationService.setEventSink(null)
                    } catch (e: Exception) {
                        Log.e(TAG, "Erro ao cancelar EventSink", e)
                    }
                }
            }
        )
    }

    private fun getSmsMessages(): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        val contentResolver: ContentResolver = this.contentResolver
        
        try {
            // URI para SMS recebidos
            val uri = Uri.parse("content://sms/inbox")
            
            // Colunas que queremos ler
            val projection = arrayOf(
                Telephony.Sms._ID,
                Telephony.Sms.ADDRESS,
                Telephony.Sms.BODY,
                Telephony.Sms.DATE,
                Telephony.Sms.TYPE
            )
            
            // Ordenar por data (mais recentes primeiro)
            val sortOrder = "${Telephony.Sms.DATE} DESC"
            
            var cursor: Cursor? = null
            try {
                cursor = contentResolver.query(uri, projection, null, null, sortOrder)
                
                cursor?.let {
                    var count = 0
                    while (it.moveToNext() && count < 50) { // Limitar a 50 mensagens
                        try {
                            val message = mapOf(
                                "id" to it.getString(it.getColumnIndexOrThrow(Telephony.Sms._ID)),
                                "address" to (it.getString(it.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)) ?: ""),
                                "body" to (it.getString(it.getColumnIndexOrThrow(Telephony.Sms.BODY)) ?: ""),
                                "date" to it.getLong(it.getColumnIndexOrThrow(Telephony.Sms.DATE)),
                                "type" to "inbox"
                            )
                            messages.add(message)
                            count++
                        } catch (e: Exception) {
                            Log.e(TAG, "Erro ao processar SMS individual", e)
                            continue
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao consultar SMS", e)
            } finally {
                cursor?.close()
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Erro geral ao ler SMS", e)
        }
        
        Log.d(TAG, "Total de SMS lidos: ${messages.size}")
        return messages
    }
    
    private fun checkNotificationAccess(): Boolean {
        return try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val activeNotifications = notificationManager.activeNotifications
                Log.d(TAG, "Verificando acesso às notificações - Total encontradas: ${activeNotifications.size}")
                
                // Se consegue acessar as notificações, tem permissão
                activeNotifications.isNotEmpty()
            } else {
                Log.d(TAG, "Versão Android < M, assumindo acesso às notificações")
                true // Em versões antigas, assume que tem acesso
            }
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao verificar acesso às notificações", e)
            false
        }
    }
    
    private fun startNotificationService() {
        try {
            NotificationService.startForegroundService(this)
            Log.d(TAG, "✅ Serviço de notificações iniciado com sucesso")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erro ao iniciar serviço de notificações", e)
            throw e
        }
    }
    
    private fun stopNotificationService() {
        try {
            NotificationService.stopForegroundService(this)
            Log.d(TAG, "✅ Serviço de notificações parado com sucesso")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erro ao parar serviço de notificações", e)
            throw e
        }
    }
    
    private fun clearSystemNotifications() {
        try {
            Log.d(TAG, "🧹 Solicitando limpeza de notificações via NotificationService")
            
            // Usar o NotificationService para limpar notificações com privilégios elevados
            NotificationService.clearAllActiveNotifications()
            
            Log.d(TAG, "✅ Comando de limpeza enviado para NotificationService")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erro ao solicitar limpeza de notificações", e)
            throw e
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "MainActivity destruída")
        
        try {
            // Limpar recursos
            backgroundExecutor.shutdown()
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao destruir MainActivity", e)
        }
    }
    
    override fun onPause() {
        super.onPause()
        Log.d(TAG, "MainActivity pausada")
    }
    
    override fun onResume() {
        super.onResume()
        Log.d(TAG, "MainActivity resumida")
    }
}
