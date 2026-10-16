package com.example.balls_99

import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

/**
 * Tam ekran (immersive) oyun etkinliği.
 *
 * Dart tarafı SystemChrome.setEnabledSystemUIMode(immersiveSticky) uygular; burada
 * ayrıca etkinlik öne geldiğinde (onResume) ve pencere odağı geri geldiğinde (bildirim paneli kapanınca, ekran kilidinden
 * dönünce, bir diyalog kapanınca) sistem çubukları yeniden gizlenir.
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Çentikli ekranlarda içerik kısa kenarlara uzanır; oyun çentik payını
        // Flutter tarafında (güvenli alan) kendisi bırakır.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes = window.attributes.apply {
                layoutInDisplayCutoutMode =
                    WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }
    }

    override fun onResume() {
        super.onResume()
        // Arka plandan dönüşte çubuklar hemen gizlensin; pencere yeniden
        // düzenlendikten sonra bir kez daha (bazı cihazlar ilk çağrıyı ezer).
        hideSystemBars()
        window.decorView.post { hideSystemBars() }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideSystemBars()
    }

    private fun hideSystemBars() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.systemBars())
                controller.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                )
        }
    }
}
