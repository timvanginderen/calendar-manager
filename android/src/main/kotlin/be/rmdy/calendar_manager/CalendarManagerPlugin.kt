package be.rmdy.calendar_manager

import android.os.Looper
import androidx.annotation.NonNull
import be.rmdy.calendar_manager.exceptions.CalendarManagerException
import be.rmdy.calendar_manager.exceptions.NotImplementedMethodException
import be.rmdy.calendar_manager.models.Calendar
import be.rmdy.calendar_manager.models.Event
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import kotlinx.coroutines.*
import kotlinx.serialization.internal.ArrayListSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonConfiguration

class CalendarManagerPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {

    private val job = Job()

    private val scope = CoroutineScope(job + Dispatchers.Main.immediate)

    private val json = Json(JsonConfiguration.Stable)
    private val delegate: CalendarManagerDelegate = CalendarManagerDelegate()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this.init(flutterPluginBinding))

    }

    private fun init(registrar: Registrar) = apply {
        delegate.context = registrar.context()
        onNewBindingDelegate(BindingDelegate.registrar(registrar))
    }

    private fun init(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) = apply {
        delegate.context = flutterPluginBinding.applicationContext
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    companion object {
        const val CHANNEL_NAME = "rmdy.be/calendar_manager"
        @Suppress("unused")
        @JvmStatic
        //for backwards compatibility
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), CHANNEL_NAME)
            channel.setMethodCallHandler(CalendarManagerPlugin().init(registrar))
        }
    }

    private fun assertMainThread() {
        check(Looper.myLooper() == Looper.getMainLooper())
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        GlobalScope.launch(context = Dispatchers.Main) {
            assertMainThread()
            sendBackResult(result, call)
        }

    }


    private suspend fun sendBackResult(result: Result, call: MethodCall) {
        try {
            result.success(handleMethod(call.method, requireNotNull(call.arguments() as Map<String, Any?>) { "arguments = null" }))
        } catch (ex: CalendarManagerException) {
            result.error(ex.errorCode, ex.errorMessage, ex.errorDetails)
        } catch (ex: NotImplementedMethodException) {
            result.notImplemented()
        } catch (ex: Exception) {
            result.error("UNKNOWN", ex.message, null)
        }
    }


    private suspend fun handleMethod(method: String, jsonArgs: Map<String, Any?>): Any? {
        println("handleMethod: $method")
        return when (method) {
            "createCalendar" -> {
                val calendar = json.parse(Calendar.serializer(), jsonArgs["calendar"] as String)
                delegate.createCalendar(calendar)
            }
            "createEvents" -> {
                val event = json.parse(ArrayListSerializer(Event.serializer()), jsonArgs["events"] as String)
                delegate.createEvents(event)
            }
            "deleteAllEventsByCalendarId" -> {
                val calendarId = jsonArgs["calendarId"] as String
                delegate.deleteAllEventsByCalendarId(calendarId)
            }
            else -> {
                throw NotImplementedMethodException()
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        delegate.activity = null
    }

    override fun onDetachedFromActivity() {
        delegate.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onNewBindingDelegate(BindingDelegate.activityPluginBinding(binding))
    }

    private fun onNewBindingDelegate(binding: BindingDelegate) {
        delegate.activity = binding.activity
        binding.removeRequestPermissionsResultListener(delegate)
        binding.addRequestPermissionsResultListener(delegate)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        onNewBindingDelegate(BindingDelegate.activityPluginBinding(binding))
    }

    override fun onDetachedFromActivityForConfigChanges() {
        delegate.activity = null
    }
}
