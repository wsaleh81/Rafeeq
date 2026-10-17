package com.wael.rafeeq;

import android.content.Context;
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
    private final float[] R = new float[9];
    private final float[] R2 = new float[9];
    private final float[] ori = new float[3];

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
        SensorManager.getRotationMatrixFromVector(R, e.values);
        float[] m = R;
        // Phone held upright (screen facing the user): report where the back of the phone points.
        if (Math.abs(R[8]) < 0.6f) {
            SensorManager.remapCoordinateSystem(R, SensorManager.AXIS_X, SensorManager.AXIS_Z, R2);
            m = R2;
        }
        SensorManager.getOrientation(m, ori);
        double az = Math.toDegrees(ori[0]) + declination;
        double rad = Math.toRadians(az);
        double a = hasSmooth ? 0.18 : 1.0;
        sx = hasSmooth ? sx + a * (Math.cos(rad) - sx) : Math.cos(rad);
        sy = hasSmooth ? sy + a * (Math.sin(rad) - sy) : Math.sin(rad);
        hasSmooth = true;
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

    @Override
    public void onAccuracyChanged(Sensor s, int acc) {
        accuracy = acc;
    }
}
