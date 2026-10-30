package com.wael.rihal;

import android.content.Context;
import android.os.Build;
import android.view.Display;
import android.view.Surface;
import android.view.WindowManager;
import android.hardware.GeomagneticField;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

/**
 * True-north compass. Uses the fused rotation-vector sensor (tilt compensated),
 * corrects magnetic declination for the user's position and smooths the result.
 */
@CapacitorPlugin(name = "Compass")
public class CompassPlugin extends Plugin implements SensorEventListener {
    private SensorManager sm;
    private Sensor rot;
    private boolean running = false;
    private float declination = 0f;
    private int accuracy = 3;
    private double sx = 0, sy = 0;
    private boolean hasSmooth = false;
    private long lastEmit = 0;
    private final float[] R0 = new float[9];
    private final float[] R = new float[9];

    @PluginMethod
    public void start(PluginCall call) {
        if (sm == null) sm = (SensorManager) getContext().getSystemService(Context.SENSOR_SERVICE);
        if (rot == null) rot = sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR);
        JSObject r = new JSObject();
        if (rot == null) {
            r.put("available", false);
            call.resolve(r);
            return;
        }
        if (!running) {
            hasSmooth = false;
            sm.registerListener(this, rot, SensorManager.SENSOR_DELAY_GAME);
            running = true;
        }
        r.put("available", true);
        call.resolve(r);
    }

    @PluginMethod
    public void stop(PluginCall call) {
        if (running && sm != null) sm.unregisterListener(this);
        running = false;
        call.resolve();
    }

    @PluginMethod
    public void setLocation(PluginCall call) {
        double lat = call.getDouble("lat", 0.0);
        double lon = call.getDouble("lon", 0.0);
        double alt = call.getDouble("alt", 0.0);
        GeomagneticField f = new GeomagneticField((float) lat, (float) lon, (float) alt, System.currentTimeMillis());
        declination = f.getDeclination();
        JSObject r = new JSObject();
        r.put("declination", declination);
        call.resolve(r);
    }

    @Override
    protected void handleOnPause() {
        if (running && sm != null) sm.unregisterListener(this);
    }

    @Override
    protected void handleOnResume() {
        if (running && sm != null && rot != null) sm.registerListener(this, rot, SensorManager.SENSOR_DELAY_GAME);
    }

    @Override
    public void onSensorChanged(SensorEvent e) {
        if (e.sensor.getType() != Sensor.TYPE_ROTATION_VECTOR) return;
        SensorManager.getRotationMatrixFromVector(R0, e.values);
        // Remap device axes to the current screen orientation so the heading follows the
        // screen's top edge in portrait AND landscape (otherwise landscape is off by 90 deg).
        switch (displayRotation()) {
            case Surface.ROTATION_90:
                SensorManager.remapCoordinateSystem(R0, SensorManager.AXIS_Y, SensorManager.AXIS_MINUS_X, R); break;
            case Surface.ROTATION_180:
                SensorManager.remapCoordinateSystem(R0, SensorManager.AXIS_MINUS_X, SensorManager.AXIS_MINUS_Y, R); break;
            case Surface.ROTATION_270:
                SensorManager.remapCoordinateSystem(R0, SensorManager.AXIS_MINUS_Y, SensorManager.AXIS_X, R); break;
            default:
                System.arraycopy(R0, 0, R, 0, 9);
        }
        // R maps device axes to world axes (x = east, y = north, z = up).
        // Heading = horizontal direction of (top edge - screen normal). This is the top of the phone
        // when it lies flat and the back camera direction when it is upright, and it changes smoothly
        // in between (no jump when tilting), like the iPhone's heading.
        double east = R[1] - R[2];
        double north = R[4] - R[5];
        if (Math.hypot(east, north) < 1e-3) return;
        double az = Math.toDegrees(Math.atan2(east, north)) + declination;
        double rad = Math.toRadians(az);
        double cx = Math.cos(rad), cy = Math.sin(rad);
        if (!hasSmooth) {
            sx = cx; sy = cy; hasSmooth = true;
        } else {
            // Adaptive low-pass: heavy filtering for sensor noise, fast follow for a real turn.
            double cur = Math.toDegrees(Math.atan2(sy, sx));
            double d = Math.abs(((az - cur) % 360 + 540) % 360 - 180);
            double a = d > 20 ? 0.5 : d > 6 ? 0.25 : 0.08;
            sx += a * (cx - sx);
            sy += a * (cy - sy);
        }
        long now = System.currentTimeMillis();
        if (now - lastEmit < 33) return;
        lastEmit = now;
        double h = Math.toDegrees(Math.atan2(sy, sx));
        if (h < 0) h += 360;
        JSObject o = new JSObject();
        o.put("heading", h);
        o.put("accuracy", accuracy);
        notifyListeners("heading", o);
    }

    @SuppressWarnings("deprecation")
    private int displayRotation() {
        try {
            Display d = null;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && getActivity() != null) d = getActivity().getDisplay();
            if (d == null) {
                WindowManager wm = (WindowManager) getContext().getSystemService(Context.WINDOW_SERVICE);
                if (wm != null) d = wm.getDefaultDisplay();
            }
            return d != null ? d.getRotation() : Surface.ROTATION_0;
        } catch (Exception ex) {
            return Surface.ROTATION_0;
        }
    }

    @Override
    public void onAccuracyChanged(Sensor s, int acc) {
        // SENSOR_STATUS_UNRELIABLE 0, LOW 1, MEDIUM 2, HIGH 3 (magnetometer calibration)
        accuracy = acc;
    }
}
