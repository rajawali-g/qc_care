package com.example.data_monitor

import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.qc_mce/network_stats"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsagePermission" -> {
                    openUsageSettings()
                    result.success(true)
                }
                "getNetworkUsage" -> {
                    val startToday = (call.argument<Number>("startToday"))?.toLong() ?: 0L
                    val startCycle = (call.argument<Number>("startCycle"))?.toLong() ?: 0L
                    val endTime = (call.argument<Number>("endTime"))?.toLong() ?: System.currentTimeMillis()

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val stats = queryNetworkUsage(startToday, startCycle, endTime)
                            result.success(stats)
                        } catch (e: Exception) {
                            result.error("STATS_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.error("UNSUPPORTED_VERSION", "Android 6.0 (API 23) ke atas diperlukan", null)
                    }
                }
                "updateWidget" -> {
                    val remainingQuota = call.argument<String>("remainingQuota") ?: "15.00 GB"
                    val percent = call.argument<Int>("percent") ?: 100
                    val todayUsage = call.argument<String>("todayUsage") ?: "Hari ini: 0 MB"
                    val cycleUsage = call.argument<String>("cycleUsage") ?: "Total: 0 / 15 GB"
                    val lastUpdated = call.argument<String>("lastUpdated") ?: "QC_MCE"

                    QCDataWidgetProvider.updateWidget(
                        context = applicationContext,
                        remainingQuota = remainingQuota,
                        percent = percent,
                        todayUsage = todayUsage,
                        cycleUsage = cycleUsage,
                        lastUpdated = lastUpdated
                    )
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageSettings() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
        } catch (e: Exception) {
            val fallbackIntent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(fallbackIntent)
        }
    }

    private fun queryNetworkUsage(startToday: Long, startCycle: Long, endTime: Long): Map<String, Long> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return emptyMap()
        }

        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager

        fun getBytesForType(networkType: Int, startTime: Long, endTime: Long): Long {
            return try {
                val bucket = networkStatsManager.querySummaryForDevice(
                    networkType,
                    null,
                    startTime,
                    endTime
                )
                bucket.rxBytes + bucket.txBytes
            } catch (e: Exception) {
                0L
            }
        }

        val todayMobile = getBytesForType(ConnectivityManager.TYPE_MOBILE, startToday, endTime)
        val cycleMobile = getBytesForType(ConnectivityManager.TYPE_MOBILE, startCycle, endTime)
        val todayWifi = getBytesForType(ConnectivityManager.TYPE_WIFI, startToday, endTime)
        val cycleWifi = getBytesForType(ConnectivityManager.TYPE_WIFI, startCycle, endTime)

        return mapOf(
            "todayMobileBytes" to todayMobile,
            "cycleMobileBytes" to cycleMobile,
            "todayWifiBytes" to todayWifi,
            "cycleWifiBytes" to cycleWifi
        )
    }
}
