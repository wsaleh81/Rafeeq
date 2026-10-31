package com.wael.rihal;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;

/** Rectangle widget: next prayer time and the nearest mosque. */
public class RihalRectWidget extends AppWidgetProvider {
    @Override
    public void onUpdate(Context c, AppWidgetManager m, int[] ids) {
        RihalWidgets.updateAll(c);
    }

    @Override
    public void onDisabled(Context c) {
        RihalWidgets.updateAll(c);
    }
}
