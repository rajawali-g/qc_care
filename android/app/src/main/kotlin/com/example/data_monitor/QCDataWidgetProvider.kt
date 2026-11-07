package com.example.data_monitor

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews

class QCDataWidgetProvider : AppWidgetProvider() {

    companion object {
        const val PREFS_NAME = "QC_MCE_WidgetPrefs"
        const val KEY_REMAINING = "remaining_quota"
        const val KEY_PERCENT = "progress_percent"
        const val KEY_TODAY = "today_usage"
        const val KEY_CYCLE = "cycle_usage"
        const val KEY_UPDATED = "last_updated"

        const val ACTION_REFRESH = "com.example.data_monitor.ACTION_REFRESH_WIDGET"

        fun updateWidget(
            context: Context,
            remainingQuota: String,
            percent: Int,
            todayUsage: String,
            cycleUsage: String,
            lastUpdated: String
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit()
                .putString(KEY_REMAINING, remainingQuota)
                .putInt(KEY_PERCENT, percent)
                .putString(KEY_TODAY, todayUsage)
                .putString(KEY_CYCLE, cycleUsage)
                .putString(KEY_UPDATED, lastUpdated)
                .apply()

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, QCDataWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)

            for (widgetId in allWidgetIds) {
                renderWidget(
                    context,
                    appWidgetManager,
                    widgetId,
                    remainingQuota,
                    percent,
                    todayUsage,
                    cycleUsage,
                    lastUpdated
                )
            }
        }

        private fun renderWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            widgetId: Int,
            remainingQuota: String,
            percent: Int,
            todayUsage: String,
            cycleUsage: String,
            lastUpdated: String
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_qc_mce)

            views.setTextViewText(R.id.tv_remaining_quota, remainingQuota)
            views.setProgressBar(R.id.progress_bar_quota, 100, percent.coerceIn(0, 100), false)
            views.setTextViewText(R.id.tv_today_usage, todayUsage)
            views.setTextViewText(R.id.tv_cycle_usage, cycleUsage)
            views.setTextViewText(R.id.tv_last_updated, lastUpdated)

            // Tap root view to open the app (MainActivity)
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingOpenApp = PendingIntent.getActivity(
                context,
                0,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingOpenApp)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        val remainingQuota = prefs.getString(KEY_REMAINING, "15.00 GB") ?: "15.00 GB"
        val percent = prefs.getInt(KEY_PERCENT, 100)
        val todayUsage = prefs.getString(KEY_TODAY, "Hari ini: 0 MB") ?: "Hari ini: 0 MB"
        val cycleUsage = prefs.getString(KEY_CYCLE, "Total: 0 / 15 GB") ?: "Total: 0 / 15 GB"
        val lastUpdated = prefs.getString(KEY_UPDATED, "QC_MCE") ?: "QC_MCE"

        for (widgetId in appWidgetIds) {
            renderWidget(
                context,
                appWidgetManager,
                widgetId,
                remainingQuota,
                percent,
                todayUsage,
                cycleUsage,
                lastUpdated
            )
        }
    }
}

