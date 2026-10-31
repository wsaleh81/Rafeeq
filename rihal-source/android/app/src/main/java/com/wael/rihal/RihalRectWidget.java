package com.wael.rihal;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.os.Bundle;

/** Rectangle widget: next prayer time and the nearest mosque. */
public class RihalRectWidget extends AppWidgetProvider {
    @Override
    public void onUpdate(Context c, AppWidgetManager m, int[] ids) {
        RihalWidgets.updateAll(c);
    }

    @Override
    public void onAppWidgetOptionsChanged(Context c, AppWidgetManager m, int id, Bundle options) {
        RihalWidgets.updateAll(c); // resized: lay the content out again for the new size
    }

    @Override
    public void onDisabled(Context c) {
        RihalWidgets.updateAll(c);
    }
}
