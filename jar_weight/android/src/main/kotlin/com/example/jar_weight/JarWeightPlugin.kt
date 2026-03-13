package com.example.jar_weight
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.io.IOException
import java.io.BufferedReader
import java.io.InputStreamReader
import java.util.*

class JarWeightPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var methodChannel: MethodChannel
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null
    private val bluetoothAdapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var connectedSocket: BluetoothSocket? = null
    private val MY_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "jar_weight/method")
        methodChannel.setMethodCallHandler(this)

        val eventChannel = EventChannel(binding.binaryMessenger, "jar_weight/scan")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, events: EventChannel.EventSink?) { eventSink = events }
            override fun onCancel(args: Any?) { eventSink = null }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPairedDevices" -> {
                val paired = bluetoothAdapter?.bondedDevices?.map {
                    mapOf("name" to (it.name ?: "Unknown"), "address" to it.address)
                } ?: listOf()
                result.success(paired)
            }
            "startScan" -> {
                val filter = IntentFilter(BluetoothDevice.ACTION_FOUND)
                context?.registerReceiver(object : BroadcastReceiver() {
                    override fun onReceive(context: Context?, intent: Intent?) {
                        if (BluetoothDevice.ACTION_FOUND == intent?.action) {
                            val device = intent.getParcelableExtra<BluetoothDevice>(BluetoothDevice.EXTRA_DEVICE)
                            device?.let {
                                val data = mapOf("type" to "device", "name" to (it.name ?: "Unknown"), "address" to it.address)
                                Handler(Looper.getMainLooper()).post { eventSink?.success(data) }
                            }
                        }
                    }
                }, filter)
                bluetoothAdapter?.startDiscovery()
                result.success(true)
            }
            "startServer" -> {
                Thread {
                    try {
                        val server = bluetoothAdapter?.listenUsingRfcommWithServiceRecord("ChatApp", MY_UUID)
                        val socket = server?.accept()
                        connectedSocket = socket
                        server?.close()
                        listenForMessages()
                        Handler(Looper.getMainLooper()).post { result.success("Connected") }
                    } catch (e: IOException) {
                        Handler(Looper.getMainLooper()).post { result.error("ERR", e.message, null) }
                    }
                }.start()
            }
            "connectToDevice" -> {
                val address = call.argument<String>("address")
                val device = bluetoothAdapter?.getRemoteDevice(address)
                Thread {
                    bluetoothAdapter?.cancelDiscovery() // ALWAYS cancel discovery before connecting
                    try {
                        // Attempt 1: Standard Secure Connection
                        connectedSocket = device?.createRfcommSocketToServiceRecord(MY_UUID)
                        Thread.sleep(200)
                        connectedSocket?.connect()
                    } catch (e: IOException) {
                        // Attempt 2: The Reflection "Backdoor" Hack
                        try {
                            val clazz = device?.javaClass
                            val method = clazz?.getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                            connectedSocket = method?.invoke(device, 1) as BluetoothSocket
                            Thread.sleep(200)
                            connectedSocket?.connect()
                        } catch (fallbackException: Exception) {
                            // If both fail, tell Flutter it failed safely
                            Handler(Looper.getMainLooper()).post {
                                result.error("ERR", "Connection refused by scale", null)
                            }
                            return@Thread
                        }
                    }

                    // If we made it here, we are connected!
                    listenForMessages()
                    Handler(Looper.getMainLooper()).post { result.success("Connected") }
                }.start()
            }
            "sendMessage" -> {
                val msg = call.argument<String>("message") ?: ""
                try {
                    connectedSocket?.outputStream?.write(msg.toByteArray())
                    result.success(true)
                } catch (e: IOException) { result.error("ERR", e.message, null) }
            }
            else -> result.notImplemented()
        }
    }

    // UPDATED FUNCTION
// UPDATED FUNCTION
    private fun listenForMessages() {
        Thread {
            try {
                val inputStream = connectedSocket?.inputStream
                val reader = BufferedReader(InputStreamReader(inputStream))

                // Use a more stable check for the while loop
                while (connectedSocket != null && connectedSocket!!.isConnected) {
                    try {
                        val line = reader.readLine()

                        if (line != null && line.isNotEmpty()) {
                            Handler(Looper.getMainLooper()).post {
                                // 🟢 Sends weight to Flutter
                                eventSink?.success(mapOf("type" to "message", "text" to line))
                            }
                        } else if (line == null) {
                            // If readLine returns null, the socket is actually closed
                            break
                        }
                    } catch (inner: IOException) {
                        // If one read fails, we break to the finally block
                        break
                    }
                }
            } catch (e: Exception) {
                // Connection setup error
            } finally {
                // 🔴 Tell Flutter we are officially disconnected
                Handler(Looper.getMainLooper()).post {
                    eventSink?.success(mapOf("type" to "disconnected"))
                }
                try {
                    connectedSocket?.close()
                } catch (e: Exception) {}
                connectedSocket = null
            }
        }.start()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        connectedSocket?.close()
    }
}