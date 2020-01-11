package be.rmdy.calendar_manager

import be.rmdy.calendar_manager.models.Calendar
import be.rmdy.calendar_manager.models.Event

interface CalendarApi {
    suspend fun createEvents(events: List<Event>)
    suspend fun deleteAllEventsByCalendarId(calendarId: String)
    suspend fun createCalendar(calendar: Calendar)
}