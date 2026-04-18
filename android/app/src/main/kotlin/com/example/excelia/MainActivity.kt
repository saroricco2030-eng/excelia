package com.example.excelia

import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * 파일 매니저 VIEW intent → Flutter bridge.
 * content:// URI는 원본 경로 접근이 불가능하므로 cacheDir에 임시 복사 후
 * 그 절대경로를 반환한다 (Flutter 파서가 일반 파일 경로를 기대).
 */
class MainActivity : FlutterActivity() {
    private val channel = "excelia/intent"
    private var pendingPath: String? = null
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel,
        )
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialPath" -> {
                    val path = pendingPath
                    pendingPath = null
                    result.success(path)
                }
                else -> result.notImplemented()
            }
        }
        purgeStaleIntentCache()
        pendingPath = resolveIntentPath(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // 콜드 스타트로 대기 중이던 경로는 덮어써 더블 오픈 방지
        pendingPath = null
        val path = resolveIntentPath(intent)
        if (path != null) {
            methodChannel?.invokeMethod("onNewFile", path)
        }
    }

    private fun resolveIntentPath(intent: Intent?): String? {
        if (intent == null) return null
        if (intent.action != Intent.ACTION_VIEW) return null
        val uri: Uri = intent.data ?: return null
        return try {
            when (uri.scheme) {
                "file" -> uri.path
                "content" -> copyContentUriToCache(uri)
                else -> null
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun copyContentUriToCache(uri: Uri): String? {
        val displayName = queryDisplayName(uri)
            ?: "shared_${System.currentTimeMillis()}.bin"
        // 파일명 충돌 방지 — 앞에 타임스탬프 부여
        val safeName = "${INTENT_CACHE_PREFIX}${System.currentTimeMillis()}_$displayName"
        val outFile = File(cacheDir, safeName)
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(outFile).use { output ->
                input.copyTo(output)
            }
        } ?: return null
        return outFile.absolutePath
    }

    private fun queryDisplayName(uri: Uri): String? {
        return try {
            // Projection을 DISPLAY_NAME 하나로 좁혀 IPC 페이로드 축소
            val projection = arrayOf(OpenableColumns.DISPLAY_NAME)
            contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0) else null
            }
        } catch (_: Exception) {
            null
        }
    }

    /// cacheDir에 누적된 오래된 intent 복사본 정리.
    /// Android가 cacheDir을 자동 회수하긴 하나 즉시 보장되지 않음 — 앱 시작 시
    /// 7일 초과된 intent_* 접두 파일을 삭제해 상한을 둔다.
    private fun purgeStaleIntentCache() {
        try {
            val cutoff = System.currentTimeMillis() - INTENT_CACHE_TTL_MS
            cacheDir.listFiles { f -> f.name.startsWith(INTENT_CACHE_PREFIX) }
                ?.filter { it.lastModified() < cutoff }
                ?.forEach { it.delete() }
        } catch (_: Exception) { /* best-effort */ }
    }

    companion object {
        private const val INTENT_CACHE_PREFIX = "intent_"
        private const val INTENT_CACHE_TTL_MS = 7L * 24 * 60 * 60 * 1000
    }
}
