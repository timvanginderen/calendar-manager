package be.rmdy.calendar_manager

import be.rmdy.calendar_manager.models.*

interface CalendarApi {
    suspend fun deleteCalendar(calendarId: String)
    suspend fun createEvent(event: Event): EventResult
    suspend fun requestPermissions(): Boolean
    suspend fun findAllCalendars(): List<CalendarResult>
    suspend fun createCalendar(calendar: CreateCalendar): CalendarResult
    suspend fun deleteAllEventsByCalendarId(calendarId: String): List<EventResult>
}