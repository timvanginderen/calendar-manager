package be.rmdy.calendar_manager

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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.serialization.internal.ArrayListSerializer
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonConfiguration
import kotlinx.serialization.serializer

class CalendarManagerPlugin : FlutterPlugin, ActivityAware, MethodCallHandler {

    private val job = Job()

    private val scope = CoroutineScope(job + Dispatchers.Main.immediate)

    lateinit var delegate: CalendarManagerDelegate

   private val json = Json(JsonConfiguration.Stable)

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this.init(flutterPluginBinding))

    }

    private fun init(registrar: Registrar) = apply {
        delegate = CalendarManagerDelegate(context = registrar.context())
        onNewBindingDelegate(BindingDelegate.registrar(registrar))
    }

    private fun init(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) = apply {
        delegate = CalendarManagerDelegate(context = flutterPluginBinding.applicationContext)
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

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        scope.launch {
            try {
                val success = handleMethod(call.method, requireNotNull(call.arguments()) { "arguments = null" })
                result.success(success)
            } catch (ex:CalendarManagerException) {
                result.error(ex.errorCode, ex.errorMessage, ex.errorDetails)
            } catch (ex:NotImplementedMethodException) {
                result.notImplemented()
            }
        }
    }

    private suspend fun handleMethod(method: String, jsonArgs: String): Any? {
       return when (method) {
            "createCalender" -> {
                val calendar = json.parse(Calendar.serializer(), jsonArgs)
                delegate.createCalendar(calendar)
            }
            "createEvents"-> {
                val event = json.parse(ArrayListSerializer(Event.serializer()), jsonArgs)
                delegate.createEvents(event)
            }
           "deleteAllEventsByCalendarId" -> {
               val calendarId = json.parse(String.serializer(), jsonArgs)
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
        binding.addRequestPermissionsResultListener(delegate)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        delegate.activity = null
    }
}
