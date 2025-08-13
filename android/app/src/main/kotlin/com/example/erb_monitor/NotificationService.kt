package com.example.erb_monitor

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.EventChannel
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import android.content.ComponentName

class NotificationService : NotificationListenerService() {
    
    companion object {
        private const val TAG = "NotificationService"
        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "erb_monitor_channel"
        private var eventSink: EventChannel.EventSink? = null
        
        // Cache thread-safe para evitar duplicatas
        private val processedNotifications = ConcurrentHashMap<String, Long>()
        private const val MAX_CACHE_SIZE = 1000
        private const val CACHE_CLEANUP_INTERVAL = 30L // minutos
        
        // Executor para operações em background
        private val backgroundExecutor: ScheduledExecutorService = Executors.newScheduledThreadPool(2)
        
        // Handler para thread principal
        private val mainHandler = Handler(Looper.getMainLooper())
        
        // Referência estática para o serviço ativo
        private var activeService: NotificationService? = null
        
        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
            Log.d(TAG, "EventSink atualizado: ${if (sink != null) "conectado" else "desconectado"}")
        }
        
        fun setActiveService(service: NotificationService?) {
            activeService = service
            Log.d(TAG, "Serviço ativo ${if (service != null) "definido" else "removido"}")
        }
        
        fun clearAllActiveNotifications() {
            try {
                activeService?.let { service ->
                    service.clearAllNotifications()
                    Log.d(TAG, "Comando para limpar notificações enviado")
                } ?: run {
                    Log.w(TAG, "Serviço não está ativo para limpar notificações")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao limpar notificações", e)
            }
        }
        
        fun startForegroundService(context: Context) {
            try {
                val intent = Intent(context, NotificationService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                Log.d(TAG, "Serviço iniciado com sucesso")
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao iniciar serviço", e)
            }
        }
        
        fun stopForegroundService(context: Context) {
            try {
                val intent = Intent(context, NotificationService::class.java)
                context.stopService(intent)
                Log.d(TAG, "Serviço parado com sucesso")
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao parar serviço", e)
            }
        }
        
        init {
            // Agendar limpeza periódica do cache
            backgroundExecutor.scheduleAtFixedRate({
                cleanupCache()
            }, CACHE_CLEANUP_INTERVAL, CACHE_CLEANUP_INTERVAL, TimeUnit.MINUTES)
        }
        
        private fun cleanupCache() {
            try {
                val currentTime = System.currentTimeMillis()
                val cutoffTime = currentTime - (CACHE_CLEANUP_INTERVAL * 60 * 1000)
                
                val iterator = processedNotifications.iterator()
                while (iterator.hasNext()) {
                    val entry = iterator.next()
                    if (entry.value < cutoffTime) {
                        iterator.remove()
                    }
                }
                
                // Se ainda estiver muito grande, remover os mais antigos
                if (processedNotifications.size > MAX_CACHE_SIZE) {
                    val sortedEntries = processedNotifications.entries.sortedBy { it.value }
                    val toRemove = sortedEntries.take(processedNotifications.size - MAX_CACHE_SIZE)
                    toRemove.forEach { processedNotifications.remove(it.key) }
                }
                
                Log.d(TAG, "Cache limpo. Tamanho atual: ${processedNotifications.size}")
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao limpar cache", e)
            }
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "NotificationService criado")
        
        try {
            // Definir este serviço como ativo
            setActiveService(this)
            
            // Iniciar como foreground service para estabilidade
            startAsForeground()
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao iniciar em primeiro plano", e)
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "NotificationService iniciado com startId: $startId")
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "NotificationService destruído")
        
        try {
            // Remover referência estática
            setActiveService(null)
            
            // Tentar reiniciar o serviço
            val intent = Intent(this, NotificationService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao reiniciar serviço", e)
        }
    }
    
    /// Método para limpar todas as notificações ativas do Android
    fun clearAllNotifications() {
        try {
            // Obter todas as notificações ativas
            val activeNotifications = activeNotifications
            
            if (activeNotifications.isEmpty()) {
                Log.d(TAG, "Nenhuma notificação ativa para limpar")
                return
            }
            
            var clearedCount = 0
            for (sbn in activeNotifications) {
                try {
                    // Não cancelar nossa própria notificação de foreground
                    if (sbn.id != NOTIFICATION_ID) {
                        cancelNotification(sbn.key)
                        clearedCount++
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Erro ao cancelar notificação ${sbn.id}", e)
                }
            }
            
            Log.d(TAG, "Notificações limpas: $clearedCount de ${activeNotifications.size}")
            
            // Enviar evento para o Flutter
            mainHandler.post {
                try {
                    val result = JSONObject().apply {
                        put("action", "notifications_cleared")
                        put("clearedCount", clearedCount)
                        put("totalCount", activeNotifications.size)
                    }
                    eventSink?.success(result.toString())
                } catch (e: Exception) {
                    Log.e(TAG, "Erro ao enviar resultado para Flutter", e)
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao limpar notificações", e)
        }
    }
    
    /// Método para iniciar o serviço em primeiro plano
    fun startAsForeground() {
        try {
            createNotificationChannel()
            startForeground(NOTIFICATION_ID, createNotification())
            Log.d(TAG, "Serviço iniciado em primeiro plano")
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao iniciar em primeiro plano", e)
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "ERB Monitor",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = "Serviço de monitoramento de notificações"
                    setShowBadge(false)
                    enableLights(false)
                    enableVibration(false)
                }
                
                val notificationManager = getSystemService(NotificationManager::class.java)
                notificationManager.createNotificationChannel(channel)
                Log.d(TAG, "Canal de notificação criado")
            } catch (e: Exception) {
                Log.e(TAG, "Erro ao criar canal de notificação", e)
            }
        }
    }
    
    private fun createNotification(): Notification {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            }
            
            val pendingIntent = PendingIntent.getActivity(
                this, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            
            return NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("ERB Monitor")
                .setContentText("Monitorando notificações em segundo plano")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setAutoCancel(false)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setCategory(NotificationCompat.CATEGORY_SERVICE)
                .build()
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao criar notificação", e)
            // Retornar notificação básica em caso de erro
            return NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("ERB Monitor")
                .setContentText("Serviço ativo")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .build()
        }
    }
    
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        try {
            super.onNotificationPosted(sbn)
            
            val packageName = sbn.packageName
            val notification = sbn.notification
            
            // Verificar se já foi processada
            val notificationKey = "${sbn.id}_${sbn.postTime}"
            if (processedNotifications.containsKey(notificationKey)) {
                return
            }
            
            // Adicionar ao cache
            processedNotifications[notificationKey] = System.currentTimeMillis()
            
            // Processar em background para não bloquear a UI
            backgroundExecutor.execute {
                try {
                    val notificationData = extractNotificationData(sbn, notification)
                    Log.d(TAG, "Notification captured from $packageName: $notificationData")
                    
                    // Enviar para o Flutter de forma segura na thread principal
                    mainHandler.post {
                        try {
                            eventSink?.success(notificationData)
                        } catch (e: Exception) {
                            Log.e(TAG, "Erro ao enviar para Flutter", e)
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Erro ao processar notificação", e)
                }
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Erro em onNotificationPosted", e)
        }
    }
    
    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        try {
            super.onNotificationRemoved(sbn)
            Log.d(TAG, "Notification removed from ${sbn.packageName}")
        } catch (e: Exception) {
            Log.e(TAG, "Erro em onNotificationRemoved", e)
        }
    }
    
    private fun extractNotificationData(sbn: StatusBarNotification, notification: Notification): String {
        val json = JSONObject()
        
        try {
            json.put("id", sbn.id)
            json.put("packageName", sbn.packageName)
            json.put("postTime", sbn.postTime)
            
            // Extrair dados de forma segura
            val extras = notification.extras
            if (extras != null) {
                json.put("title", extras.getString(Notification.EXTRA_TITLE) ?: "")
                json.put("text", extras.getString(Notification.EXTRA_TEXT) ?: "")
                json.put("bigText", extras.getString(Notification.EXTRA_BIG_TEXT) ?: "")
                json.put("infoText", extras.getString(Notification.EXTRA_INFO_TEXT) ?: "")
                json.put("subText", extras.getString(Notification.EXTRA_SUB_TEXT) ?: "")
                json.put("summaryText", extras.getString(Notification.EXTRA_SUMMARY_TEXT) ?: "")
                
                // Informações adicionais limitadas
                val additionalInfo = JSONObject()
                val allKeys = extras.keySet()
                
                for (key in allKeys) {
                    try {
                        val value = extras.get(key)
                        if (value != null && value.toString().length < 500) { // Limitar tamanho
                            additionalInfo.put(key, value.toString())
                        }
                    } catch (e: Exception) {
                        // Ignorar chaves problemáticas
                        continue
                    }
                }
                
                json.put("additionalInfo", additionalInfo)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting notification data", e)
            json.put("error", e.message ?: "Unknown error")
        }
        
        return json.toString()
    }
    
    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "NotificationListener conectado")
    }
    
    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.e(TAG, "NotificationListener desconectado")
        
        // Tentar reconectar
        try {
            // Usar ComponentName correto para reconectar
            val componentName = ComponentName(this, NotificationService::class.java)
            requestRebind(componentName)
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao tentar reconectar", e)
        }
    }
} 