//package com.example.jar_weight
//
//import android.bluetooth.*
//import android.bluetooth.le.*
//import android.content.Context
//import android.os.Handler
//import android.os.Looper
//import java.util.*
//
//class BluetoothManager(
//    private val context: Context,
//    private val sendWeight: (Double) -> Unit
//) {
//
//    private val bluetoothAdapter: BluetoothAdapter? =
//        BluetoothAdapter.getDefaultAdapter()
//
//    private var bluetoothGatt: BluetoothGatt? = null
//
//    private val scanner: BluetoothLeScanner?
//        get() = bluetoothAdapter?.bluetoothLeScanner
//
//    private val handler = Handler(Looper.getMainLooper())
//
//    // ⚠ Replace with your real UUID
//    private val SERVICE_UUID =
//        UUID.fromString("0000181D-0000-1000-8000-00805F9B34FB")
//
//    private val CHARACTERISTIC_UUID =
//        UUID.fromString("00002A9D-0000-1000-8000-00805F9B34FB")
//
//    fun startScan() {
//        scanner?.startScan(scanCallback)
//
//        handler.postDelayed({
//            scanner?.stopScan(scanCallback)
//        }, 5000)
//    }
//
//    private val scanCallback = object : ScanCallback() {
//        override fun onScanResult(callbackType: Int, result: ScanResult?) {
//            result?.device?.let { device ->
//                scanner?.stopScan(this)
//                connectDevice(device)
//            }
//        }
//    }
//
//    private fun connectDevice(device: BluetoothDevice) {
//        bluetoothGatt = device.connectGatt(context, false, gattCallback)
//    }
//
//    private val gattCallback = object : BluetoothGattCallback() {
//
//        override fun onConnectionStateChange(
//            gatt: BluetoothGatt,
//            status: Int,
//            newState: Int
//        ) {
//            if (newState == BluetoothProfile.STATE_CONNECTED) {
//                gatt.discoverServices()
//            }
//        }
//
//        override fun onServicesDiscovered(
//            gatt: BluetoothGatt,
//            status: Int
//        ) {
//            val service = gatt.getService(SERVICE_UUID)
//            val characteristic =
//                service?.getCharacteristic(CHARACTERISTIC_UUID)
//
//            characteristic?.let {
//                gatt.setCharacteristicNotification(it, true)
//            }
//        }
//
//        override fun onCharacteristicChanged(
//            gatt: BluetoothGatt,
//            characteristic: BluetoothGattCharacteristic
//        ) {
//            if (characteristic.uuid == CHARACTERISTIC_UUID) {
//                val value = characteristic.value
//                val weight = parseWeight(value)
//                sendWeight(weight)
//            }
//        }
//    }
//
//    private fun parseWeight(data: ByteArray): Double {
//        return try {
//            String(data).toDouble()
//        } catch (e: Exception) {
//            0.0
//        }
//    }
//}
