package com.coldmint.rustassistant.rebuild

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.core.net.toUri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

class MainActivity : FlutterActivity() {

    companion object {
        private const val ANDROID_CHANNEL = "Android_Channel"
        private const val FLUTTER_CHANNEL = "Flutter_Channel"
        private const val PERMISSION_REQUEST_CODE = 1001
    }

    private var permissionResult: MethodChannel.Result? = null
    private var flutterChannel: MethodChannel? = null

    private var unintroducedModPath: String? = null;

    /**
     * 从uri获取文件名称
     * @param uri Uri uri
     * @return String? 文件格式无法获取返回null
     */
    fun getFileName(uri: Uri?): String? {
        if (uri == null) {
            return null
        }
        val path = uri.path
        return if (path != null) {
            val index = path.lastIndexOf("/")
            if (index > -1) {
                path.substring(index + 1)
            } else {
                null
            }
        } else {
            null
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        //处理App已启动，且从其他页面打开文件。
        copyMod(intent)
    }

    fun copyMod(intent: Intent) {
        val intent = intent
        val uri = intent.data
        val fileName = getFileName(uri)
        if (fileName != null && uri != null) {
            //将文件复制到内部存储路径内。
            copyFileToCacheDirectory(uri, fileName)
            unintroducedModPath = File(cacheDir, fileName).absolutePath
            flutterChannel?.invokeMethod("importMod", unintroducedModPath)
        }
    }


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ANDROID_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPersistedUriPermissions" -> {
                        val list = contentResolver.persistedUriPermissions.map {
                            mapOf(
                                "uri" to it.uri.toString(),
                                "readPermission" to it.isReadPermission,
                                "writePermission" to it.isWritePermission
                            )
                        }
                        result.success(list)
                    }

                    "releasePersistableUriPermission" -> {
                        val uriStr = call.argument<String>("uri")
                        val flags = call.argument<Int>("flags") ?: 0
                        if (uriStr != null) {
                            contentResolver.releasePersistableUriPermission(
                                uriStr.toUri(),
                                flags
                            )
                            result.success(true)
                        } else {
                            result.error("INVALID_URI", "URI is null", null)
                        }
                    }

                    "checkPermissions" -> {
                        val read = ContextCompat.checkSelfPermission(
                            context,
                            Manifest.permission.READ_EXTERNAL_STORAGE
                        ) == PackageManager.PERMISSION_GRANTED
                        val write = ContextCompat.checkSelfPermission(
                            context,
                            Manifest.permission.WRITE_EXTERNAL_STORAGE
                        ) == PackageManager.PERMISSION_GRANTED
                        val manage =
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                Environment.isExternalStorageManager()
                            } else {
                                true
                            }
                        result.success(
                            mapOf(
                                "READ_EXTERNAL_STORAGE" to read,
                                "WRITE_EXTERNAL_STORAGE" to write,
                                "MANAGE_EXTERNAL_STORAGE" to manage
                            )
                        )
                    }

                    "openStoragePermissionSetting" -> {
                        openStoragePermissionSetting()
                        result.success(true)
                    }

                    "deleteUnintroducedModPath" -> {
                        val filePath = unintroducedModPath
                        if (filePath == null) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        val file = File(filePath)
                        if (file.exists()) {
                            file.delete()
                        }
                        unintroducedModPath = null
                        result.success(true)
                    }

                    "requestPermissions" -> {
                        permissionResult = result
                        requestAllStoragePermissions()
                    }

                    "externalStoragePath" -> {
                        val externalStorageDir = Environment.getExternalStoragePublicDirectory("")
                        result.success(externalStorageDir.absolutePath)
                    }

                    else -> result.notImplemented()
                }
            }
        flutterChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FLUTTER_CHANNEL)
        //处理App尚未启动，且从其他页面打开文件。
        copyMod(intent)
    }


    private fun copyFileToCacheDirectory(uri: Uri, fileName: String) {
        val inputStream: InputStream? = contentResolver.openInputStream(uri)
        val cacheDir = cacheDir // 获取应用的缓存目录
        if (!cacheDir.exists()) {
            cacheDir.mkdirs()
        }
        val outputFile = File(cacheDir, fileName)
        val outputStream = FileOutputStream(outputFile)
        inputStream?.use { input ->
            outputStream.use { output ->
                input.copyTo(output)
            }
        }
        inputStream?.close()
        outputStream.close()
    }

    //打开管理App存储设置页面
    private fun openStoragePermissionSetting() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val intent =
                    Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                intent.data = "package:$packageName".toUri()
                startActivity(intent)
            } catch (_: Exception) {
                val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                startActivity(intent)
            }
        } else {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = "package:$packageName".toUri()
            }
            startActivity(intent)
        }
    }

    private fun requestAllStoragePermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            if (!Environment.isExternalStorageManager()) {
                try {
                    val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION)
                    intent.data = "package:$packageName".toUri()
                    startActivityForResult(intent, PERMISSION_REQUEST_CODE)
                } catch (_: Exception) {
                    val intent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION)
                    startActivityForResult(intent, PERMISSION_REQUEST_CODE)
                }
            } else {
                // 如果已经有 MANAGE_EXTERNAL_STORAGE 权限，仍然申请旧的存储权限以兼容
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(
                        Manifest.permission.READ_EXTERNAL_STORAGE,
                        Manifest.permission.WRITE_EXTERNAL_STORAGE
                    ),
                    PERMISSION_REQUEST_CODE
                )
            }
        } else {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(
                    Manifest.permission.READ_EXTERNAL_STORAGE,
                    Manifest.permission.WRITE_EXTERNAL_STORAGE
                ),
                PERMISSION_REQUEST_CODE
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            permissionResult?.success(granted)
            permissionResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                Environment.isExternalStorageManager()
            } else {
                true
            }
            permissionResult?.success(granted)
            permissionResult = null
        }
    }
}

