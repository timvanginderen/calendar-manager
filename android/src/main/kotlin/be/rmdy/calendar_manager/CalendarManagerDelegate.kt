package be.rmdy.calendar_manager

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.provider.CalendarContract
import android.provider.CalendarContract.Calendars
import android.provider.CalendarContract.Events
import android.util.Log
import be.rmdy.calendar_manager.exceptions.CalendarManagerException
import be.rmdy.calendar_manager.models.*
import be.rmdy.calendar_manager.permissions.PermissionService
import io.flutter.plugin.common.PluginRegistry
import java.util.*
import kotlin.collections.ArrayList


class CalendarManagerDelegate : CalendarApi, PluginRegistry.RequestPermissionsResultListener {
    var activity: Activity? = null
    var context: Context? = null

    private val permissionService = PermissionService()

    override suspend fun findAllCalendars(): List<CalendarResult> {
        val projection = arrayOf(
                Calendars._ID,
                Calendars.CALENDAR_DISPLAY_NAME,
                Calendars.CALENDAR_ACCESS_LEVEL,
                Calendars.CALENDAR_COLOR)
  
        val uri = Calendars.CONTENT_URI
        val results = ArrayList<CalendarResult>()
        val contentResolver = context!!.contentResolver
        val cursor = contentResolver.query(uri, projection, null, null, null)
        cursor?.use { cursor ->
            while (cursor.moveToNext()) {
                val id = cursor.getStringByName(Calendars._ID)!!
                val name = cursor.getStringByName(Calendars.CALENDAR_DISPLAY_NAME) ?: ""
                val accessLevel = cursor.getIntByName(Calendars.CALENDAR_ACCESS_LEVEL)!!
                val color = cursor.getIntByName(Calendars.CALENDAR_COLOR)?.takeIf { it>0 }
                val calendar = CalendarResult(id = id, name = name, color = color, isReadOnly = accessLevel <= Calendars.CAL_ACCESS_READ)
                results += calendar
            }
        }

        return results

    }

    private fun Event.toCreateEventResult(eventId:String?): EventResult {
        return EventResult(
                calendarId = calendarId,
                description = description,
                location = location,
                title = title,
                endDate = endDate,
                eventId = eventId,
                startDate = startDate
        )
    }

    override suspend fun createEvent(event: Event): EventResult {
        validateCalendarId(event.calendarId)
        val cr = context!!.contentResolver
        val values = ContentValues()
        val timeZone = TimeZone.getDefault()
        values.put(Events.DTSTART, event.startDate?.time)
        values.put(Events.DTEND, event.endDate?.time)
        values.put(Events.EVENT_LOCATION, event.location)
        values.put(Events.EVENT_TIMEZONE, timeZone.id)
        values.put(Events.TITLE, event.title)
        values.put(Events.DESCRIPTION, event.description)
        values.put(Events.CALENDAR_ID, event.calendarId)
        val uri = cr.insert(Events.CONTENT_URI, values)
        // Retrieve ID for new event
        val eventID = uri?.lastPathSegment
        Log.d(TAG, "event added with id: $eventID")
        return event.toCreateEventResult(eventID)
    }

    override suspend fun requestPermissions(): Boolean {
        return permissionService.requestPermissionsIfNeeded(activity!!, PERMISSIONS)
    }

    override suspend fun createCalendar(calendar: CreateCalendar): CalendarResult {
        validateCalendarId(calendar.id)
        val account = calendar.name
        val accountType = CalendarContract.ACCOUNT_TYPE_LOCAL
        val v = ContentValues()
        v.put(Calendars.NAME, calendar.name)
        v.put(Calendars.CALENDAR_DISPLAY_NAME, calendar.name)
        v.put(Calendars.ACCOUNT_NAME, account)
        v.put(Calendars.ACCOUNT_TYPE, accountType)
        v.put(Calendars.CALENDAR_COLOR, calendar.color)
        v.put(Calendars.CALENDAR_ACCESS_LEVEL, Calendars.CAL_ACCESS_OWNER)
        v.put(Calendars.OWNER_ACCOUNT, account)
        v.put(Calendars._ID, calendar.id)
        v.put(Calendars.SYNC_EVENTS, 1)
        v.put(Calendars.VISIBLE, 1)
        val creationUri: Uri = asSyncAdapter(Calendars.CONTENT_URI, account, accountType)
        val calendarData: Uri? = context!!.contentResolver.insert(creationUri, v)
        if (calendarData != null) {
            Log.d(TAG, "Calendar created with id: " + calendarData.lastPathSegment)
        } else {
            Log.d(TAG, "Calendar found with id: " + calendar.id)
        }
        return CalendarResult(id = calendar.id, color = calendar.color, isReadOnly = false, name = calendar.name)
    }

    private fun Long.toDate() = Date(this)

    override suspend fun deleteAllEventsByCalendarId(calendarId: String): List<EventResult> {
        val projection = arrayOf(
                Events._ID,
                Events.DTSTART,
                Events.DTEND,
                Events.TITLE,
                Events.DESCRIPTION,
                Events.EVENT_LOCATION,
                Events.CALENDAR_ID,
                Events._ID)

        val uri = Events.CONTENT_URI
        val results = ArrayList<EventResult>()
        val contentResolver = context!!.contentResolver
        val cursor = contentResolver.query(uri, projection, "${Events.CALENDAR_ID}=?", arrayOf(calendarId), null)
        cursor?.use { c ->
            while (c.moveToNext()) {
                val id = c.getLongByName(Events._ID)
                val startDate = c.getLongByName(Events.DTSTART)?.toDate()
                val endDate = c.getLongByName(Events.DTEND)?.toDate()
                val title = c.getStringByName(Events.TITLE)
                val cursorCalendarId = c.getLongByName(Events.CALENDAR_ID)!!
                val description = c.getStringByName(Events.DESCRIPTION)
                val location = c.getStringByName(Events.EVENT_LOCATION)
                check(cursorCalendarId.toString() == calendarId)

                val event = EventResult(
                        eventId = id?.toString(),
                        startDate = startDate,
                        endDate = endDate,
                        title = title,
                        calendarId = calendarId,
                        location = location,
                        description = description
                )
                results += event
            }
        }

        val rows = contentResolver.delete(Events.CONTENT_URI, Events.CALENDAR_ID + "=?", arrayOf(calendarId))
        check(rows == results.size)
        return results
    }

    override suspend fun deleteCalendar(calendarId: String) {
        validateCalendarId(calendarId)
        val calendar = findCalendarByIdOrThrow(calendarId, requireWritable = false)
        val cr = context!!.contentResolver
        val uri = asSyncAdapter(ContentUris.withAppendedId(Calendars.CONTENT_URI, calendarId.toLong()),
                calendar.name, CalendarContract.ACCOUNT_TYPE_LOCAL)
        val rows = cr.delete(uri, null, null)
        Log.d(TAG, "deleteCalendar: $rows")
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
        return permissionService.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    private fun String.isNumbersOnly() = this.all { it.isDigit() }

    private fun validateCalendarId(calendarId: String) {
        require(calendarId.isNotEmpty()) {
            "calendarId must not be empty"
        }
        require(calendarId.isNumbersOnly()) {
            "calendarId ($calendarId) must be a number"
        }
    }


    private fun asSyncAdapter(uri: Uri, account: String, accountType: String): Uri {
        return uri.buildUpon().appendQueryParameter(CalendarContract.CALLER_IS_SYNCADAPTER, "true")
                .appendQueryParameter(Calendars.ACCOUNT_NAME, account).appendQueryParameter(Calendars.ACCOUNT_TYPE, accountType).build()
    }


    private fun errorCalendarNotFound(calendarId: String) = CalendarManagerException(code = ErrorCode.CALENDAR_NOT_FOUND, message = "Calendar with id not found: $calendarId", details = calendarId)

    private fun errorCalendarReadOnly(calendarResult: CalendarResult) = CalendarManagerException(code = ErrorCode.CALENDAR_READ_ONLY, message = "Calendar is read only: $calendarResult", details = calendarResult.toString())


    private suspend fun findCalendarByIdOrThrow(calendarId: String, requireWritable: Boolean = true): CalendarResult {
        validateCalendarId(calendarId)
        val calendar = findAllCalendars().find { it.id == calendarId }
                ?: throw errorCalendarNotFound(calendarId)
        if (requireWritable && calendar.isReadOnly) {
            throw errorCalendarReadOnly(calendar)
        }
        return calendar
    }

    companion object {
        private const val TAG = "CalendarManagerDelegate"
        private val PERMISSIONS = listOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR)
    }

    private fun Cursor.getStringByName(colName: String): String? {
        val index=  getColumnIndexOrThrow(colName)
        if(isNull(index))
            return null
        return getString(index)
    }


    private fun Cursor.getLongByName(colName: String): Long? {
        val index=  getColumnIndexOrThrow(colName)
        if(isNull(index))
            return null
        return getLong(index)
    }

    private fun Cursor.getIntByName(colName: String): Int? {
        val index=  getColumnIndexOrThrow(colName)
        if(isNull(index))
            return null
        return getInt(index)
    }

}

