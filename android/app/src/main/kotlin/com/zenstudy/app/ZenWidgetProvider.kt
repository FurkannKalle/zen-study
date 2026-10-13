package com.zenstudy.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONObject

class ZenWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            try {
                val views = RemoteViews(context.packageName, R.layout.zen_widget).apply {
                    val statsJson = widgetData.getString("weekly_stats", null)
                    var streak = 0
                    val dayNames = arrayOf("Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz")
                    val dayCounts = IntArray(7) { 0 }
                    
                    if (statsJson != null) {
                        try {
                            val json = JSONObject(statsJson)
                            streak = json.optInt("streak", 0)
                            if (json.has("days")) {
                                val daysObj = json.getJSONObject("days")
                                for (i in 0..6) {
                                    dayCounts[i] = daysObj.optInt(dayNames[i], 0)
                                }
                            }
                        } catch (e: Exception) {
                            e.printStackTrace()
                        }
                    }
                    
                    setTextViewText(R.id.streak_text, "$streak Gün Ateş")
                    
                    // Günleri ve skorları renklendir
                    val countIds = intArrayOf(R.id.count_0, R.id.count_1, R.id.count_2, R.id.count_3, R.id.count_4, R.id.count_5, R.id.count_6)
                    val dayIds = intArrayOf(R.id.day_0, R.id.day_1, R.id.day_2, R.id.day_3, R.id.day_4, R.id.day_5, R.id.day_6)
                    
                    for (i in 0..6) {
                        val count = dayCounts[i]
                        val countStr = if (count > 0) count.toString() else "-"
                        setTextViewText(countIds[i], countStr)
                        
                        if (count > 0) {
                            setTextColor(countIds[i], Color.parseColor("#1A3626")) // Canlı yeşil (Koyu orman yeşili)
                            setTextColor(dayIds[i], Color.parseColor("#2E5C40")) 
                        } else {
                            setTextColor(countIds[i], Color.parseColor("#A0AAB2")) // Soluk gri
                            setTextColor(dayIds[i], Color.parseColor("#A0AAB2"))
                        }
                    }

                    // Cihazdaki widgeta tıklayınca uygulamayı direkt açacak ve deep link iletecek Intent
                    val intent = android.content.Intent(context, MainActivity::class.java).apply {
                        action = "es.antonborri.home_widget.action.LAUNCH"
                        data = android.net.Uri.parse("zen://focus")
                    }
                    
                    var flags = android.app.PendingIntent.FLAG_UPDATE_CURRENT
                    if (android.os.Build.VERSION.SDK_INT >= 23) {
                        flags = flags or android.app.PendingIntent.FLAG_IMMUTABLE
                    }
                    val pendingIntent = android.app.PendingIntent.getActivity(context, 0, intent, flags)
                    setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                }
                appWidgetManager.updateAppWidget(widgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
