package com.example.data_monitor

import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.TrafficStats
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

    private var lastSampleTime: Long = 0L
    private var lastTotalRxBytes: Long = 0L
    private var lastTotalTxBytes: Long = 0L
    private var lastMobileRxBytes: Long = 0L

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
                "getAppNetworkUsage" -> {
                    val startTime = (call.argument<Number>("startTime"))?.toLong() ?: 0L
                    val endTime = (call.argument<Number>("endTime"))?.toLong() ?: System.currentTimeMillis()

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val appStats = queryAppNetworkUsage(startTime, endTime)
                            result.success(appStats)
                        } catch (e: Exception) {
                            result.error("APP_STATS_ERROR", e.localizedMessage, null)
                        }
                    } else {
                        result.success(emptyList<Map<String, Any>>())
                    }
                }
                "getRealtimeSpeed" -> {
                    result.success(getRealtimeSpeed())
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

    private fun queryAppNetworkUsage(startTime: Long, endTime: Long): List<Map<String, Any>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return emptyList()

        val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
        val mobileMap = HashMap<Int, Long>()
        val wifiMap = HashMap<Int, Long>()

        try {
            val statsMobile = networkStatsManager.querySummary(ConnectivityManager.TYPE_MOBILE, null, startTime, endTime)
            val bucket = NetworkStats.Bucket()
            while (statsMobile.hasNextBucket()) {
                statsMobile.getNextBucket(bucket)
                val current = mobileMap.getOrDefault(bucket.uid, 0L)
                mobileMap[bucket.uid] = current + bucket.rxBytes + bucket.txBytes
            }
            statsMobile.close()
        } catch (e: Exception) {}

        try {
            val statsWifi = networkStatsManager.querySummary(ConnectivityManager.TYPE_WIFI, null, startTime, endTime)
            val bucket = NetworkStats.Bucket()
            while (statsWifi.hasNextBucket()) {
                statsWifi.getNextBucket(bucket)
                val current = wifiMap.getOrDefault(bucket.uid, 0L)
                wifiMap[bucket.uid] = current + bucket.rxBytes + bucket.txBytes
            }
            statsWifi.close()
        } catch (e: Exception) {}

        val allUids = HashSet<Int>()
        allUids.addAll(mobileMap.keys)
        allUids.addAll(wifiMap.keys)

        val resultList = ArrayList<Map<String, Any>>()
        val pm = packageManager

        for (uid in allUids) {
            val mobileBytes = mobileMap.getOrDefault(uid, 0L)
            val wifiBytes = wifiMap.getOrDefault(uid, 0L)
            if (mobileBytes == 0L && wifiBytes == 0L) continue

            var appName = "Process (UID $uid)"
            var pkgName = "unknown"

            val packages = pm.getPackagesForUid(uid)
            if (!packages.isNullOrEmpty()) {
                pkgName = packages[0]
                try {
                    val appInfo = pm.getApplicationInfo(pkgName, 0)
                    appName = pm.getApplicationLabel(appInfo).toString()
                } catch (e: Exception) {
                    appName = pkgName
                }
            } else if (uid == 1000) {
                appName = "Android System"
                pkgName = "android.system"
            }

            // Check if socket is live active
            val liveSocketBytes = TrafficStats.getUidRxBytes(uid) + TrafficStats.getUidTxBytes(uid)

            resultList.add(mapOf(
                "uid" to uid,
                "appName" to appName,
                "packageName" to pkgName,
                "mobileBytes" to mobileBytes,
                "wifiBytes" to wifiBytes,
                "isLive" to (liveSocketBytes > 0L)
            ))
        }

        // Automatic descending sort by largest quota consumption (Operator Mobile bytes first, then total)
        resultList.sortByDescending { (it["mobileBytes"] as Long) + (it["wifiBytes"] as Long) }
        return resultList
    }

    private fun getRealtimeSpeed(): Map<String, Any> {
        val now = System.currentTimeMillis()
        val totalRx = TrafficStats.getTotalRxBytes()
        val totalTx = TrafficStats.getTotalTxBytes()
        val mobileRx = TrafficStats.getMobileRxBytes()

        var rxSpeedKb = 0.0
        var txSpeedKb = 0.0
        var mobileSpeedKb = 0.0

        if (lastSampleTime > 0L && now > lastSampleTime) {
            val deltaSec = (now - lastSampleTime) / 1000.0
            if (deltaSec > 0.0) {
                rxSpeedKb = ((totalRx - lastTotalRxBytes) / 1024.0) / deltaSec
                txSpeedKb = ((totalTx - lastTotalTxBytes) / 1024.0) / deltaSec
                mobileSpeedKb = ((mobileRx - lastMobileRxBytes) / 1024.0) / deltaSec
            }
        }

        lastSampleTime = now
        lastTotalRxBytes = totalRx
        lastTotalTxBytes = totalTx
        lastMobileRxBytes = mobileRx

        return mapOf(
            "rxSpeedKb" to rxSpeedKb.coerceAtLeast(0.0),
            "txSpeedKb" to txSpeedKb.coerceAtLeast(0.0),
            "mobileSpeedKb" to mobileSpeedKb.coerceAtLeast(0.0),
            "totalRxBytes" to totalRx
        )
    }
}
