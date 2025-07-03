package com.example.mopro_flutter_example

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    private var eventSink: EventChannel.EventSink? = null
    private val eventChannel = "com.moprowallet/events"
    private var pendingLink: String? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannel)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    
                    // Send any pending link that was received during cold start
                    pendingLink?.let { link ->
                        eventSink?.success(link)
                        pendingLink = null
                    }
                }
                
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val uri: Uri? = intent.data
            uri?.let {
                val link = it.toString()
                
                // Try to send immediately if eventSink is ready
                if (eventSink != null) {
                    eventSink?.success(link)
                } else {
                    // Store the link for when Flutter is ready
                    pendingLink = link
                }
            }
        }
    }
}
