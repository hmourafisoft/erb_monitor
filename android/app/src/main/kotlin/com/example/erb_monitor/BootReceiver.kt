package com.example.erb_monitor

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.d(TAG, "Boot completado - iniciando ERB Monitor")
                startNotificationService(context)
            }
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "App atualizado - iniciando ERB Monitor")
                startNotificationService(context)
            }
            Intent.ACTION_PACKAGE_REPLACED -> {
                Log.d(TAG, "Pacote atualizado - verificando se é o ERB Monitor")
                val packageName = intent.data?.schemeSpecificPart
                if (packageName == context.packageName) {
                    Log.d(TAG, "ERB Monitor atualizado - iniciando serviço")
                    startNotificationService(context)
                }
            }
        }
    }
    
    private fun startNotificationService(context: Context) {
        try {
            // Aguardar um pouco para o sistema estar pronto
            Thread.sleep(5000)
            
            // Iniciar o serviço de notificações
            NotificationService.startForegroundService(context)
            
            Log.d(TAG, "Serviço de notificações iniciado com sucesso")
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao iniciar serviço de notificações", e)
        }
    }
}
