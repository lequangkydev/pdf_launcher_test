package com.example.pdf_launcher_demo

import android.app.WallpaperManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.util.Base64
import android.util.DisplayMetrics
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.pdf_launcher_demo/launcher"

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return FlutterEngineCache.getInstance().get(App.ENGINE_ID)
    }

    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isDefaultLauncher" -> result.success(isDefaultLauncher())
                    "openDefaultHomeSettings" -> {
                        openDefaultHomeSettings()
                        result.success(true)
                    }
                    "getInstalledApps" -> {
                        Thread {
                            val apps = getInstalledApps()
                            runOnUiThread { result.success(apps) }
                        }.start()
                    }
                    "launchApp" -> {
                        val packageName = call.argument<String>("packageName")
                        if (packageName != null) {
                            launchApp(packageName)
                            result.success(true)
                        } else {
                            result.error("INVALID", "packageName required", null)
                        }
                    }
                    "getPdfFiles" -> {
                        Thread {
                            val files = getPdfFiles()
                            runOnUiThread { result.success(files) }
                        }.start()
                    }
                    "getWallpaper" -> {
                        Thread {
                            val wallpaper = getWallpaperBase64()
                            runOnUiThread { result.success(wallpaper) }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }

    @Suppress("DEPRECATION")
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        moveTaskToBack(true)
    }

    private fun isDefaultLauncher(): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_MAIN)
            intent.addCategory(Intent.CATEGORY_HOME)
            val resolveInfo = packageManager.resolveActivity(
                intent, PackageManager.MATCH_DEFAULT_ONLY
            )
            resolveInfo?.activityInfo?.packageName == packageName
        } catch (e: Exception) {
            false
        }
    }

    private fun openDefaultHomeSettings() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                startActivity(Intent(Settings.ACTION_HOME_SETTINGS))
            } else {
                val intent = Intent(Intent.ACTION_MAIN)
                intent.addCategory(Intent.CATEGORY_HOME)
                startActivity(Intent.createChooser(intent, "Select Home App"))
            }
        } catch (e: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_SETTINGS))
            } catch (_: Exception) {}
        }
    }

    private fun getInstalledApps(): List<Map<String, String>> {
        val intent = Intent(Intent.ACTION_MAIN)
        intent.addCategory(Intent.CATEGORY_LAUNCHER)

        val resolveInfos: List<ResolveInfo> = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.queryIntentActivities(
                intent, PackageManager.ResolveInfoFlags.of(0)
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.queryIntentActivities(intent, 0)
        }

        val apps = mutableListOf<Map<String, String>>()
        val myPackage = packageName

        for (info in resolveInfos) {
            val pkg = info.activityInfo.packageName
            // Skip our own app
            if (pkg == myPackage) continue

            val label = info.loadLabel(packageManager).toString()
            val icon = info.loadIcon(packageManager)
            val iconBase64 = drawableToBase64(icon)

            apps.add(mapOf(
                "label" to label,
                "packageName" to pkg,
                "icon" to iconBase64
            ))
        }

        return apps.sortedBy { it["label"]?.lowercase() }
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = drawableToBitmap(drawable, 96)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 90, stream)
        val bytes = stream.toByteArray()
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }

    private fun drawableToBitmap(drawable: Drawable, size: Int): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return Bitmap.createScaledBitmap(drawable.bitmap, size, size, true)
        }
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, size, size)
        drawable.draw(canvas)
        return bitmap
    }

    private fun launchApp(targetPackage: String) {
        try {
            val intent = packageManager.getLaunchIntentForPackage(targetPackage)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            }
        } catch (_: Exception) {}
    }

    private fun getPdfFiles(): List<Map<String, Any>> {
        val pdfFiles = mutableListOf<Map<String, Any>>()

        // Search common directories
        val directories = listOf(
            Environment.getExternalStorageDirectory(),
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
        )

        val visited = mutableSetOf<String>()
        for (dir in directories) {
            if (dir.exists()) {
                searchPdfFiles(dir, pdfFiles, visited, 0)
            }
        }

        return pdfFiles.sortedByDescending { it["lastModified"] as Long }
    }

    private fun getWallpaperBase64(): String? {
        return try {
            val wallpaperManager = WallpaperManager.getInstance(this)
            @Suppress("DEPRECATION")
            val drawable = wallpaperManager.drawable ?: return null

            // Get screen dimensions for proper scaling
            val metrics = DisplayMetrics()
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getMetrics(metrics)
            val screenWidth = metrics.widthPixels
            val screenHeight = metrics.heightPixels

            val bitmap = drawableToBitmapFull(drawable, screenWidth, screenHeight)
            val stream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, 80, stream)
            val bytes = stream.toByteArray()
            Base64.encodeToString(bytes, Base64.NO_WRAP)
        } catch (e: Exception) {
            null
        }
    }

    private fun drawableToBitmapFull(drawable: Drawable, width: Int, height: Int): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return Bitmap.createScaledBitmap(drawable.bitmap, width, height, true)
        }
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, width, height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun searchPdfFiles(
        dir: File,
        result: MutableList<Map<String, Any>>,
        visited: MutableSet<String>,
        depth: Int
    ) {
        // Limit recursion depth to avoid hanging
        if (depth > 5) return
        val canonical = dir.canonicalPath
        if (visited.contains(canonical)) return
        visited.add(canonical)

        val files = dir.listFiles() ?: return
        for (file in files) {
            if (file.isDirectory && !file.name.startsWith(".")) {
                searchPdfFiles(file, result, visited, depth + 1)
            } else if (file.isFile && file.extension.equals("pdf", ignoreCase = true)) {
                result.add(mapOf(
                    "name" to file.name,
                    "path" to file.absolutePath,
                    "size" to file.length(),
                    "lastModified" to file.lastModified()
                ))
            }
        }
    }
}
