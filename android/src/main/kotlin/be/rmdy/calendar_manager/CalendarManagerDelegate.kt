package be.rmdy.calendar_manager

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.provider.CalendarContract
import android.util.Log
import be.rmdy.calendar_manager.exceptions.CalendarManagerException
import be.rmdy.calendar_manager.models.Calendar
import be.rmdy.calendar_manager.models.Event
import be.rmdy.calendar_manager.permissions.PermissionService
import io.flutter.plugin.common.PluginRegistry
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonConfiguration
import kotlinx.serialization.serializer
import java.util.*

class CalendarManagerDelegate : CalendarApi, PluginRegistry.RequestPermissionsResultListener {
    var activity: Activity? = null
    var context: Context? = null
    private val json = Json(JsonConfiguration.Stable)

    private val permissionService = PermissionService()

    private fun createEvent(event: Event) {
        val cr = context!!.contentResolver
        val values = ContentValues()
        val timeZone = TimeZone.getDefault()
        values.put(CalendarContract.Events.DTSTART, event.startDate.time)
        values.put(CalendarContract.Events.DTEND, event.endDate.time)
        values.put(CalendarContract.Events.EVENT_LOCATION, event.location)
        values.put(CalendarContract.Events.EVENT_TIMEZONE, timeZone.id)
        values.put(CalendarContract.Events.TITLE, event.title)
        values.put(CalendarContract.Events.DESCRIPTION, event.description)
        values.put(CalendarContract.Events.CALENDAR_ID, event.calendarId)
        val uri = cr.insert(CalendarContract.Events.CONTENT_URI, values)
        // Retrieve ID for new event
        val eventID = uri?.lastPathSegment
        Log.d(TAG, "event added with id: $eventID")
    }

    private fun ok(): String = json.stringify(String.serializer(), "ok")

    override suspend fun createEvents(events: List<Event>): String? {
        requestPermissionsIfNeeded()
        events.forEach {
            createEvent(it)
        }
        return null
    }

    override suspend fun deleteAllEventsByCalendarId(calendarId: String): String? {
        requestPermissionsIfNeeded()
        val cr = context!!.contentResolver
        val rows = cr.delete(CalendarContract.Events.CONTENT_URI, CalendarContract.Events.CALENDAR_ID + "=?", arrayOf(calendarId))
        Log.d(TAG, "Removed $rows existing events from your calendar")
        return null
    }

    private suspend fun requestPermissionsIfNeeded() {
        val isGranted = permissionService.requestPermissionsIfNeeded(activity!!, listOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR))
        if (!isGranted) {
            throwPermissionsNotGrantedError()
        }
    }

    private fun throwPermissionsNotGrantedError() {
        throw CalendarManagerException(errorCode = ErrorCodes.PERMISSIONS_NOT_GRANTED)
    }

    override suspend fun createCalendar(calendar: Calendar): String? {
        requestPermissionsIfNeeded()
        val account = calendar.name
        val accountType = CalendarContract.ACCOUNT_TYPE_LOCAL
        val v = ContentValues()
        v.put(CalendarContract.Calendars.NAME, calendar.name)
        v.put(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME, calendar.name)
        v.put(CalendarContract.Calendars.ACCOUNT_NAME, account)
        v.put(CalendarContract.Calendars.ACCOUNT_TYPE, accountType)
        v.put(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL, CalendarContract.Calendars.CAL_ACCESS_OWNER)
        v.put(CalendarContract.Calendars.OWNER_ACCOUNT, account)
        v.put(CalendarContract.Calendars._ID, calendar.id)
        v.put(CalendarContract.Calendars.SYNC_EVENTS, 1)
        v.put(CalendarContract.Calendars.VISIBLE, 1)
        val creationUri: Uri = asSyncAdapter(CalendarContract.Calendars.CONTENT_URI, account, accountType)
        val calendarData: Uri? = context!!.contentResolver.insert(creationUri, v)
        if (calendarData != null) {
            Log.d(TAG, "Calendar created with id: " + calendarData.lastPathSegment)
        } else {
            Log.d(TAG, "Calendar found with id: " + calendar.id)
        }
        return null
    }

    private fun asSyncAdapter(uri: Uri, account: String, accountType: String): Uri {
        return uri.buildUpon().appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true").appendQueryParameter(CalendarContract.Calendars.ACCOUNT_NAME, account).appendQueryParameter(CalendarContract.Calendars.ACCOUNT_TYPE, accountType).build()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
        return permissionService.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    companion object {
        private const val TAG = "CalendarManagerDelegate"
    }
}