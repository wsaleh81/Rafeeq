package com.wael.rihal;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.os.Bundle;
import android.content.Intent;

/** Square widget: next prayer with the countdown ring. Also receives the shared refresh tick. */
public class RihalSquareWidget extends AppWidgetProvider {
    @Override
    public void onReceive(Context c, Intent i) {
        String a = i.getAction();
        if (RihalWidgets.ACTION_TICK.equals(a) || Intent.ACTION_TIME_CHANGED.equals(a) || Intent.ACTION_TIMEZONE_CHANGED.equals(a)) {
            RihalWidgets.updateAll(c);
            return;
        }
        super.onReceive(c, i);
    }

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
