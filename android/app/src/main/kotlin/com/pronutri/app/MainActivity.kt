package com.pronutri.app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private var detectorHandler: StepDetectorStreamHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        detectorHandler = StepDetectorStreamHandler(applicationContext)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "pronutri/step_detector_raw"
        ).setStreamHandler(detectorHandler)
    }

    override fun onDestroy() {
        detectorHandler?.dispose()
        detectorHandler = null
        super.onDestroy()
    }
}

private class StepDetectorStreamHandler(
    private val context: Context
) : EventChannel.StreamHandler, SensorEventListener {
    private val sensorManager: SensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val stepDetector: Sensor? = sensorManager.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
    private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        if (stepDetector == null) {
            events?.error(
                "NO_STEP_DETECTOR",
                "Step detector sensor not available",
                "TYPE_STEP_DETECTOR is unavailable on this device"
            )
            return
        }

        sensorManager.registerListener(
            this,
            stepDetector,
            SensorManager.SENSOR_DELAY_NORMAL
        )
    }

    override fun onCancel(arguments: Any?) {
        sensorManager.unregisterListener(this)
        sink = null
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_STEP_DETECTOR) {
            val steps = event.values.firstOrNull()?.toInt() ?: 1
            sink?.success(if (steps > 0) steps else 1)
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // no-op
    }

    fun dispose() {
        sensorManager.unregisterListener(this)
        sink = null
    }
}
