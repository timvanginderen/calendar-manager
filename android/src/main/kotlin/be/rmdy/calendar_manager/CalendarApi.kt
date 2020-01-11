package be.rmdy.calendar_manager

import be.rmdy.calendar_manager.models.Calendar
import be.rmdy.calendar_manager.models.Event

interface CalendarApi {
    suspend fun createEvents(events: List<Event>):String?
    suspend fun deleteAllEventsByCalendarId(calendarId: String):String?
    suspend fun createCalendar(calendar: Calendar):String?
}