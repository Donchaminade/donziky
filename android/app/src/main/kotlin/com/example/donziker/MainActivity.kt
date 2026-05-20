package com.example.donziker

import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.util.Rational
import android.app.PictureInPictureParams
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceActivity() {
    private val channelName = "com.example.donziker/media"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "setRingtone" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrEmpty()) {
                        result.success(false)
                    } else {
                        result.success(setRingtone(path))
                    }
                }
                "enterPip" -> {
                    result.success(enterPipMode())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setRingtone(path: String): Boolean {
        return try {
            val file = File(path)
            if (!file.exists()) return false
            val uri = Uri.fromFile(file)
            RingtoneManager.setActualDefaultRingtoneUri(
                this,
                RingtoneManager.TYPE_RINGTONE,
                uri
            )
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun enterPipMode(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            enterPictureInPictureMode(params)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
