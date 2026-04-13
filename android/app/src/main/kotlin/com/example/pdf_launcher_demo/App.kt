package com.example.pdf_launcher_demo

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class App : Application() {
    companion object {
        const val ENGINE_ID = "main_engine"
    }

    lateinit var flutterEngine: FlutterEngine

    override fun onCreate() {
        super.onCreate()

        // Pre-warm the Flutter engine at Application level
        // so it survives Activity recreation
        flutterEngine = FlutterEngine(this)
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        // Cache it globally
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine)
    }
}
