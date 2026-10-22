package com.example.donziker

import android.content.Context
import android.os.PowerManager

/**
 * ExoPlayer (just_audio) est créé sans setWakeMode : écran éteint, le CPU
 * s'endort et le décodage s'arrête. Ce verrou partiel suit le processus,
 * pas la fenêtre, et survit à la destruction de l'activité.
 */
object PlaybackWakeLock {
    private var lock: PowerManager.WakeLock? = null

    fun acquire(context: Context) {
        val app = context.applicationContext
        val pm = app.getSystemService(Context.POWER_SERVICE) as PowerManager
        val current = lock ?: pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "donziker:playback").also {
            it.setReferenceCounted(false)
            lock = it
        }
        if (!current.isHeld) {
            current.acquire()
        }
    }

    fun release() {
        val current = lock ?: return
        if (current.isHeld) {
            current.release()
        }
    }
}
