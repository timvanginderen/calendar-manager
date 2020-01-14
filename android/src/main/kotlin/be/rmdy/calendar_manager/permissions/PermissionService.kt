package be.rmdy.calendar_manager.permissions

import android.app.Activity
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CompletableDeferred

class PermissionService : PluginRegistry.RequestPermissionsResultListener {
    companion object {
        private const val TAG = "PermissionService"
        private const val REQUEST_CODE: Int = 1345431138
        private var grantedCompleter: CompletableDeferred<Boolean>? = null
    }


    fun hasPermissions(activity: Activity, permissions: List<String>): Boolean {
        val notGrantedPermissions = permissions.filter {
            ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED
        }
        return notGrantedPermissions.isEmpty()
    }


    suspend fun requestPermissionsIfNeeded(activity: Activity, permissions: List<String>): Boolean {
        Log.d(TAG, "requestPermissionsIfNeeded: $permissions")
        val notGrantedPermissions = permissions.filter {
            ContextCompat.checkSelfPermission(activity, it) != PackageManager.PERMISSION_GRANTED
        }
        return if (notGrantedPermissions.isNotEmpty()) {
            grantedCompleter?.let {
                if (it.isActive)
                    it.cancel()
            }
            grantedCompleter = CompletableDeferred()
            ActivityCompat.requestPermissions(activity, permissions.toTypedArray(), REQUEST_CODE)
            grantedCompleter!!.await()
        } else
            true
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
        Log.d(TAG, "onRequestPermissionsResult: $requestCode, $permissions, $grantResults")
        return when (requestCode) {
            REQUEST_CODE -> {
                val granted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                grantedCompleter?.complete(granted)
                true
            }
            else -> false
        }
    }
}